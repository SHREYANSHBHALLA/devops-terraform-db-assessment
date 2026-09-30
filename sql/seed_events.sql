INSERT INTO booking_events (booking_id, event_type, event_data, created_at)
SELECT
    id,
    (
        ARRAY[
            'booking_created',
            'payment_completed',
            'booking_confirmed',
            'booking_cancelled'
        ]
    )[floor(random() * 4 + 1)::int],
    jsonb_build_object(
        'source', 'web',
        'processed', true
    ),
    created_at + (random() * INTERVAL '2 days')
FROM hotel_bookings;