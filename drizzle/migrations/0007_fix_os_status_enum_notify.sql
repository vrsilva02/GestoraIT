CREATE OR REPLACE FUNCTION public.fn_notify_os_change()
RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
    v_hostname text;
BEGIN
    SELECT hostname INTO v_hostname FROM public.ativos WHERE id = NEW.ativo_id;

    INSERT INTO public.user_notifications (user_id, title, message, type)
    SELECT user_id, 
           'OS #' || NEW.numero || ' - Mudança de Status',
           'O ativo ' || COALESCE(v_hostname, 'desconhecido') || ' mudou de ' || COALESCE(OLD.status::text, 'N/A') || ' para ' || NEW.status::text || ' em ' || to_char(now(), 'DD/MM/YYYY HH24:MI'),
           'os_alert'
    FROM public.user_roles 
    WHERE role IN ('admin', 'gestor_ti');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS tr_os_status_notify ON public.ordens_servico;
CREATE TRIGGER tr_os_status_notify
AFTER UPDATE OF status ON public.ordens_servico
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.fn_notify_os_change();

CREATE OR REPLACE FUNCTION public.fn_os_concluida() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
  IF NEW.status='concluida' AND OLD.status IS DISTINCT FROM 'concluida' THEN
    NEW.data_conclusao := COALESCE(NEW.data_conclusao, now());
    UPDATE public.ativos
      SET status_ciclo_vida=COALESCE(NEW.status_ativo_anterior,'em_uso'), data_ultima_transicao=now()
      WHERE id=NEW.ativo_id AND status_ciclo_vida='manutencao';
    INSERT INTO public.ativos_historico_status (ativo_id, status_anterior, status_novo, observacao)
      VALUES (NEW.ativo_id, 'manutencao', COALESCE(NEW.status_ativo_anterior,'em_uso'), 'Conclusão da OS');
  ELSIF NEW.status IN ('aberta', 'em_andamento', 'aguardando_peca') AND OLD.status = 'concluida' THEN
    NEW.data_conclusao := NULL;
    UPDATE public.ativos
      SET status_ciclo_vida='manutencao', data_ultima_transicao=now()
      WHERE id=NEW.ativo_id AND status_ciclo_vida<>'manutencao';
    INSERT INTO public.ativos_historico_status (ativo_id, status_anterior, status_novo, observacao)
      VALUES (NEW.ativo_id, 'em_uso', 'manutencao', 'Reabertura de OS #' || NEW.id::text);
  END IF;
  RETURN NEW;
END; $$;
