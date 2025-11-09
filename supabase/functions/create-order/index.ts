import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

function envOrThrow(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`${name} env var is required`);
  return v;
}

const SUPABASE_URL = envOrThrow("SUPABASE_URL");
const SUPABASE_ANON_KEY = envOrThrow("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = envOrThrow("SUPABASE_SERVICE_ROLE_KEY");

type NewOrderItem = {
  item_id: string;
  quantity: number;
};

type NewOrderPayload = {
  recipient_name: string;
  shipping_address: string;
  items: NewOrderItem[];
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed, use POST" }),
      {
        status: 405,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  // Read and validate Authorization header (Bearer JWT)
  const authHeader = req.headers.get("authorization") ?? "";
  const accessToken = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length)
    : null;

  if (!accessToken) {
    return new Response(
      JSON.stringify({
        error: "Missing Authorization: Bearer <access_token>",
      }),
      {
        status: 401,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  // Client that acts AS THE USER (RLS enforced)
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: `Bearer ${accessToken}` },
    },
  });

  // Verify token & get auth.uid()
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData?.user) {
    return new Response(JSON.stringify({ error: "Invalid or expired token" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  const authUid = userData.user.id;

  // Parse body (new order payload)
  let payload: NewOrderPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { recipient_name, shipping_address, items } = payload ?? {};

  if (!recipient_name || !shipping_address) {
    return new Response(
      JSON.stringify({
        error: "Missing required fields: recipient_name, shipping_address",
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  if (!Array.isArray(items) || items.length === 0) {
    return new Response(
      JSON.stringify({ error: "Order must contain at least one item" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  // Insert into orders as the authenticated user
  const {
    data: newOrder,
    error: orderError,
  } = await userClient
    .from("orders")
    .insert({
      profile_id: authUid,
      recipient_name,
      shipping_address,
    })
    .select(
      "id, profile_id, recipient_name, shipping_address, created_at, updated_at",
    )
    .single();

  if (orderError || !newOrder) {
    console.error("Error inserting order:", orderError);
    return new Response(JSON.stringify({ error: "Failed to insert order" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Insert order_items as the authenticated user
  const itemsToInsert = items.map((it) => ({
    order_id: newOrder.id,
    item_id: it.item_id,
    quantity: it.quantity,
  }));

  const { error: itemsError } = await userClient
    .from("order_items")
    .insert(itemsToInsert);

  if (itemsError) {
    console.error("Error inserting order_items:", itemsError);
    return new Response(
      JSON.stringify({ error: "Failed to insert order items" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  // Call RPC with service-role to get totals of other orders
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const {
    data: totalsData,
    error: totalsError,
  } = await adminClient.rpc("get_other_orders_total", {
    exclude_order_id: newOrder.id,
  });

  if (totalsError) {
    console.error("Error calling get_other_orders_total:", totalsError);
    return new Response(
      JSON.stringify({
        error:
          "Order created, but failed to calculate totals for other orders",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  let otherOrdersTotal = 0;
  if (Array.isArray(totalsData) && totalsData.length > 0) {
    const val = (totalsData[0] as any).total;
    otherOrdersTotal = typeof val === "number" ? val : Number(val ?? 0);
  }

  // Final response
  const data = {
    newOrder,
    otherOrdersTotal,
  };

  return new Response(JSON.stringify(data), {
    status: 201,
    headers: { "Content-Type": "application/json" },
  });
});
