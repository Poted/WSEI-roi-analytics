with source as (
    select * from {{ source('olist', 'olist_order_items') }}
),

renamed as (
    select
        order_id,
        order_item_id::int                              as item_seq,
        product_id,
        seller_id,
        shipping_limit_date::timestamp                  as shipping_limit_at,
        coalesce(price::numeric, 0)                     as item_price_brl,
        coalesce(freight_value::numeric, 0)             as freight_brl,
        coalesce(price::numeric, 0)
            + coalesce(freight_value::numeric, 0)       as item_total_brl
    from source
    where order_id is not null
)

select * from renamed
