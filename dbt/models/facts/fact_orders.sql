{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

payments as (
    select
        order_id,
        sum(payment_value_brl)  as total_revenue_brl,
        count(*)                as payment_count
    from {{ ref('stg_olist__order_payments') }}
    group by order_id
),

items as (
    select
        order_id,
        count(*)                as item_count,
        sum(item_price_brl)     as items_value_brl,
        sum(freight_brl)        as freight_total_brl
    from {{ ref('stg_olist__order_items') }}
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.purchase_date                         as date_id,
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.shipped_at,
        o.delivered_at,
        o.estimated_delivery_date,

        coalesce(p.total_revenue_brl, 0)        as total_revenue_brl,
        coalesce(i.item_count, 0)               as item_count,
        coalesce(i.items_value_brl, 0)          as items_value_brl,
        coalesce(i.freight_total_brl, 0)        as freight_total_brl,

        case when o.order_status = 'delivered' then true else false end as is_delivered
    from orders o
    left join payments p on o.order_id = p.order_id
    left join items i    on o.order_id = i.order_id
)

select * from final
