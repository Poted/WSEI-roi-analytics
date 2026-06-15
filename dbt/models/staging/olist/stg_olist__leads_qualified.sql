with source as (
    select * from {{ source('olist', 'olist_leads_qualified') }}
),

renamed as (
    select
        mql_id,
        first_contact_date::date    as first_contact_date,
        landing_page_id,
        lower(trim(origin))         as acquisition_channel
    from source
    where mql_id is not null
)

select * from renamed
