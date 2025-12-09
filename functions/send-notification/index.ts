// Supabase Edge Function: send-notification
// Deploy this to handle OneSignal notifications securely

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!
const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_API_URL = 'https://onesignal.com/api/v1/notifications'

serve(async (req) => {
    try {
        // CORS headers
        if (req.method === 'OPTIONS') {
            return new Response('ok', {
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST',
                    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
                },
            })
        }

        // Verify authentication
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { 'Content-Type': 'application/json' },
            })
        }

        // Parse request body
        const { type, userId, tagKey, tagValue, wing, flatNumber, title, message, data } = await req.json()

        // Build OneSignal notification payload
        let payload: any = {
            app_id: ONESIGNAL_APP_ID,
            headings: { en: title },
            contents: { en: message },
            android_channel_id: 'crescent_gate_alarm_v1',
            priority: 10,
            ttl: 3600,
            content_available: true,
            mutable_content: true,
            data: data || {},
        }

        // Add targeting based on type
        if (type === 'user') {
            // Target specific user by external ID
            payload.include_aliases = { external_id: [userId] }
            payload.include_external_user_ids = [userId]
            payload.channel_for_external_user_ids = 'push'
        } else if (type === 'tag') {
            // Target users by tag (e.g., role=guard)
            payload.filters = [
                { field: 'tag', key: tagKey, relation: '=', value: tagValue }
            ]
        } else if (type === 'flat') {
            // Target specific flat (wing + flat number)
            payload.filters = [
                { field: 'tag', key: 'wing', relation: '=', value: wing.toUpperCase() },
                { operator: 'AND' },
                { field: 'tag', key: 'flat_number', relation: '=', value: flatNumber.toUpperCase() }
            ]
        } else {
            return new Response(JSON.stringify({ error: 'Invalid notification type' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' },
            })
        }

        // Send notification to OneSignal
        const response = await fetch(ONESIGNAL_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
            },
            body: JSON.stringify(payload),
        })

        const result = await response.json()

        if (!response.ok) {
            console.error('OneSignal Error:', result)
            return new Response(JSON.stringify({ error: 'Failed to send notification', details: result }), {
                status: response.status,
                headers: { 'Content-Type': 'application/json' },
            })
        }

        return new Response(JSON.stringify({ success: true, result }), {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            },
        })

    } catch (error) {
        console.error('Error:', error)
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
