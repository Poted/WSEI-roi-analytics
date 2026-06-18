{{ config(materialized='table') }}

with date_spine as (
    select
        generate_series('2016-01-01'::date, '2019-12-31'::date, '1 day'::interval)::date as date_day
),

enriched as (
    select
        date_day                                                as date_id,
        date_day,

        extract(year from date_day)::int                       as year,
        extract(quarter from date_day)::int                    as quarter,
        extract(month from date_day)::int                      as month_num,
        to_char(date_day, 'Month')                             as month_name,
        to_char(date_day, 'Mon')                               as month_abbr,

        extract(week from date_day)::int                       as week_of_year,
        extract(isodow from date_day)::int                     as day_of_week,   -- 1=Mon, 7=Sun
        to_char(date_day, 'Day')                               as day_name,
        extract(day from date_day)::int                        as day_of_month,

        extract(doy from date_day)::int                        as day_of_year,

        (extract(isodow from date_day) in (6, 7))              as is_weekend,

        to_char(date_day, 'YYYY-MM')                           as year_month,
        to_char(date_day, 'YYYY-"Q"Q')                         as year_quarter
    from date_spine
)

select * from enriched
