INSERT INTO hotel_bookings (org_id, city, status, amount, created_at)
SELECT
    (
        ARRAY[
            '11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222',
            '33333333-3333-3333-3333-333333333333'
        ]::uuid[]
    )[floor(random() * 3 + 1)::int],

    (
        ARRAY[
            'delhi',
            'mumbai',
            'bangalore',
            'pune',
            'chennai'
        ]
    )[floor(random() * 5 + 1)::int],

    (
        ARRAY[
            'confirmed',
            'cancelled',
            'pending',
            'completed'
        ]
    )[floor(random() * 4 + 1)::int],

    round((1000 + random() * 9000)::numeric, 2),

    NOW() - (random() * INTERVAL '60 days')

FROM generate_series(1, 150);