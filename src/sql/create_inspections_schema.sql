create schema if not exists inspections;

create temp table inspections_outcomes as (
select event_id, entity_id, date,
   (result = 'fail') as failed,
   (result = 'fail' and
       ('serious' = ANY(array_agg(obj ->> 'severity')) or 'critical' = ANY(array_agg(obj ->> 'severity')))
   ) as failed_major_violation
from
   (select event_id, entity_id, date, result, jsonb_array_elements(violations::jsonb) as obj from semantic.events)
as t1
group by event_id, entity_id, date, result
);


drop table if exists inspections.failed;

create table inspections.failed as (
select
entity_id,
date as outcome_date,
failed as outcome
from inspections_outcomes
);


drop table if exists inspections.failed_major_violation;

create table inspections.failed_major_violation as (
select
entity_id,
date as outcome_date,
failed_major_violation as outcome
from inspections_outcomes
);

drop table if exists inspections.active_facilities;

create table inspections.active_facilities as (
select
distinct
entity_id, 'active'::VARCHAR  as state, start_time, coalesce(end_time, '2020-12-31'::date) as end_time
from semantic.entities
);
