DROP POLICY IF EXISTS os_tecnico_insert ON public.ordens_servico;
CREATE POLICY os_tecnico_insert ON public.ordens_servico FOR INSERT TO authenticated
WITH CHECK ((SELECT public.can_operate_os(auth.uid())));