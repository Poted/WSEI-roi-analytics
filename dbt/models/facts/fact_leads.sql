{{ config(materialized='table') }}

with qualified as (
    select * from {{ ref('stg_olist__leads_qualified') }}
),

closed as (
    select * from {{ ref('stg_olist__leads_closed') }}
),

channels as (
    select channel_id, channel_key
    from {{ ref('dim_channel') }}
),

joined as (
    select
        q.mql_id,
        q.first_contact_date                                as date_id,
        q.first_contact_date,
        q.acquisition_channel,
        ch.channel_id,

        c.seller_id,
        c.won_date,
        c.business_segment,
        c.lead_type,
        c.lead_behaviour_profile,
        c.business_type,
        c.declared_catalog_size,
        c.declared_monthly_revenue_brl,

        case when c.mql_id is not null then true else false end  as is_closed,
        case
            when c.won_date is not null and q.first_contact_date is not null
            then c.won_date - q.first_contact_date
            else null
        end                                                      as days_to_close
    from qualified q
    left join closed  c  on q.mql_id = c.mql_id
    left join channels ch on q.acquisition_channel = ch.channel_key
)

select * from joined
