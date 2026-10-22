-- Migration 001: Add customer_id to document_group, make case_file_id nullable
-- Run once on existing local/prod databases.

USE aseint;

ALTER TABLE document_group
  MODIFY COLUMN case_file_id BIGINT NULL,
  ADD COLUMN customer_id BIGINT NULL AFTER case_file_id,
  ADD CONSTRAINT fk_dg_customer FOREIGN KEY (customer_id) REFERENCES customer (id);
