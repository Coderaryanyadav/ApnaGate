import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotificationPayload {
  title: string;
  message: string;
  target_subscription_ids?: string[];
  target_tags?: Array<{ field: string; key: string; relation: string; value: string }>;
  data?: Record<string, unknown>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") || "5e9deb0b-b39a-4259-ae19-5f9d05840b03";
    const oneSignalApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

    if (!oneSignalApiKey) {
      return new Response(
        JSON.stringify({ error: "Missing ONESIGNAL_REST_API_KEY secret" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { title, message, target_subscription_ids, target_tags, data }: NotificationPayload = await req.json();

    const body: Record<string, unknown> = {
      app_id: oneSignalAppId,
      headings: { en: title },
      contents: { en: message },
      data: data || {},
      android_sound: "notification",
      priority: 10,
    };

    if (target_subscription_ids && target_subscription_ids.length > 0) {
      body.include_subscription_ids = target_subscription_ids;
    } else if (target_tags && target_tags.length > 0) {
      body.filters = target_tags;
    } else {
      return new Response(
        JSON.stringify({ error: "Either target_subscription_ids or target_tags must be provided" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        Authorization: `Basic ${oneSignalApiKey}`,
      },
      body: JSON.stringify(body),
    });

    const result = await response.json();
    return new Response(JSON.stringify(result), {
      status: response.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
