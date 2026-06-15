with source as (
    select * from {{ source('olist', 'olist_order_payments') }}
),

renamed as (
    select
        order_id,
        payment_sequential::int                 as payment_seq,
        lower(trim(payment_type))               as payment_type,
        payment_installments::int               as installments,
        coalesce(payment_value::numeric, 0)     as payment_value_brl
    from source
    where order_id is not null
)

select * from renamed
