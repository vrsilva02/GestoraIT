-- Migração: Permissões de Gestão, Edição/Exclusão de OS e melhorias no Módulo de Estoque e Peças

-- 1. Adicionar valor 'troca' ao enum mov_tipo se ainda não existir
ALTER TYPE public.mov_tipo ADD VALUE IF NOT EXISTS 'troca';

-- 2. Adicionar campo numero_serie em pecas_catalogo e estoque_movimentacoes
ALTER TABLE public.pecas_catalogo ADD COLUMN IF NOT EXISTS numero_serie text;
ALTER TABLE public.estoque_movimentacoes ADD COLUMN IF NOT EXISTS numero_serie text;

-- 3. Atualizar view vw_estoque_saldo para contabilizar 'troca' como saída/substituição de estoque
-- Usamos m.tipo::text para permitir criação segura mesmo dentro do mesmo bloco de transação
CREATE OR REPLACE VIEW public.vw_estoque_saldo WITH (security_invoker=true) AS
SELECT p.id AS peca_id, p.nome, p.categoria, p.fabricante,
  p.estoque_minimo, p.custo_unitario, p.fornecedor_padrao,
  COALESCE(SUM(CASE WHEN m.tipo::text='entrada' THEN m.quantidade
                    WHEN m.tipo::text='saida' THEN -m.quantidade
                    WHEN m.tipo::text='ajuste' THEN m.quantidade
                    WHEN m.tipo::text='troca' THEN -m.quantidade
                    ELSE 0 END),0)::int AS saldo
FROM public.pecas_catalogo p
LEFT JOIN public.estoque_movimentacoes m ON m.peca_id=p.id
GROUP BY p.id;

GRANT SELECT ON public.vw_estoque_saldo TO authenticated;

-- 4. Trigger ao excluir OS: se o ativo estava em manutenção e não possui outra OS pendente, reverter status
CREATE OR REPLACE FUNCTION public.fn_os_deletada() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.ordens_servico 
    WHERE ativo_id = OLD.ativo_id AND id <> OLD.id AND status NOT IN ('concluida', 'cancelada')
  ) THEN
    UPDATE public.ativos
      SET status_ciclo_vida = COALESCE(OLD.status_ativo_anterior, 'em_uso'), data_ultima_transicao = now()
      WHERE id = OLD.ativo_id AND status_ciclo_vida = 'manutencao';
  END IF;
  RETURN OLD;
END; $$;

DROP TRIGGER IF EXISTS tg_os_deletada ON public.ordens_servico;
CREATE TRIGGER tg_os_deletada BEFORE DELETE ON public.ordens_servico
FOR EACH ROW EXECUTE FUNCTION public.fn_os_deletada();

-- 5. Atualizar cache do schema do PostgREST imediatamente
NOTIFY pgrst, 'reload schema';
