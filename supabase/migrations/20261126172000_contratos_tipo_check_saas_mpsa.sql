-- Migração: Permitir SaaS e MPSA na constraint contratos_tipo_contrato_check
ALTER TABLE public.contratos
  DROP CONSTRAINT IF EXISTS contratos_tipo_contrato_check;

ALTER TABLE public.contratos
  ADD CONSTRAINT contratos_tipo_contrato_check
  CHECK (tipo_contrato IN ('CSP', 'EA', 'MPSA', 'NCE', 'Open Value', 'Perpetua', 'SaaS', 'Outro'));

NOTIFY pgrst, 'reload schema';
