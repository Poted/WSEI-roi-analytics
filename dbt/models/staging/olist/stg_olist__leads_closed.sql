with source as (
    select * from {{ source('olist', 'olist_leads_closed') }}
),

renamed as (
    select
        mql_id,
        seller_id,
        won_date::date                                          as won_date,
        lower(trim(business_segment))                          as business_segment,
        lower(trim(lead_type))                                 as lead_type,
        lower(trim(lead_behaviour_profile))                    as lead_behaviour_profile,
        lower(trim(business_type))                             as business_type,
        declared_product_catalog_size::int                     as declared_catalog_size,
        coalesce(declared_monthly_revenue::numeric, 0)         as declared_monthly_revenue_brl
    from source
    where mql_id is not null
)

select * from renamed
