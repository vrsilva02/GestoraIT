-- Migração: Excluir ativos Nobreak e Monitor do alerta "sem EDR" e bloquear associação de licenças/softwares

-- 1. Atualizar a view vw_gap_edr para ignorar ativos Nobreak e Monitor
CREATE OR REPLACE VIEW public.vw_gap_edr
WITH (security_invoker = true) AS
SELECT
  a.id AS ativo_id,
  a.hostname,
  a.setor,
  a.status_ciclo_vida
FROM public.ativos a
WHERE a.status_ciclo_vida = 'em_uso'
  AND COALESCE(a.tipo, '') !~* '(nobreak|no[\s-]?break|monitor)'
  AND COALESCE(a.categoria, '') !~* '(nobreak|no[\s-]?break|monitor)'
  AND NOT EXISTS (
    SELECT 1 FROM public.alocacoes al
    JOIN public.licencas l ON l.id = al.licenca_id
    JOIN public.produtos_catalogo pc ON pc.id = l.produto_id
    WHERE al.ativo_id = a.id
      AND al.data_fim IS NULL
      AND pc.categoria = 'EDR'
  );

GRANT SELECT ON public.vw_gap_edr TO authenticated;

-- 2. Trigger de integridade: impedir associação de licenças/softwares a ativos Nobreak ou Monitor
CREATE OR REPLACE FUNCTION public.fn_bloquear_alocacao_ativo_sem_software() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tipo text;
  v_categoria text;
BEGIN
  IF NEW.ativo_id IS NOT NULL AND NEW.data_fim IS NULL THEN
    SELECT tipo, categoria INTO v_tipo, v_categoria
    FROM public.ativos
    WHERE id = NEW.ativo_id;

    IF COALESCE(v_tipo, '') ~* '(nobreak|no[\s-]?break|monitor)'
       OR COALESCE(v_categoria, '') ~* '(nobreak|no[\s-]?break|monitor)' THEN
      RAISE EXCEPTION 'Ativos do tipo Nobreak e Monitor não podem receber associação de licenças de software.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tg_bloquear_alocacao_ativo_sem_software ON public.alocacoes;
CREATE TRIGGER tg_bloquear_alocacao_ativo_sem_software
  BEFORE INSERT OR UPDATE OF ativo_id, data_fim ON public.alocacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_bloquear_alocacao_ativo_sem_software();

NOTIFY pgrst, 'reload schema';
