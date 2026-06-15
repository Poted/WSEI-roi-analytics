with source as (
    select * from {{ source('olist', 'olist_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        lower(trim(order_status))                           as order_status,
        order_purchase_timestamp::timestamp                 as purchased_at,
        order_purchase_timestamp::date                      as purchase_date,
        order_approved_at::timestamp                        as approved_at,
        order_delivered_carrier_date::timestamp             as shipped_at,
        order_delivered_customer_date::timestamp            as delivered_at,
        order_estimated_delivery_date::date                 as estimated_delivery_date
    from source
    where order_id is not null
)

select * from renamed
