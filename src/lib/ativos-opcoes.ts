/**
 * Listas padronizadas de Tipo e Categoria de ativos (padrão de catálogo do cliente).
 * Mantidas fora dos componentes para reuso em formulários, filtros e importação.
 */

export const ATIVO_TIPOS = [
  "NOTEBOOK",
  "DESKTOP",
  "MINI PC",
  "MONITOR",
  "NOBREAK 600VA",
  "NOBREAK 1200VA",
  "WORKSTATION",
  "MACBOOK",
  "TABLET",
  "CHROMEBOOK",
  "TELA INTERATIVA",
  "GABINETE DE RECARGA",
] as const;

export const ATIVO_CATEGORIAS = [
  "Notebook",
  "Microcomputador TIPO I",
  "Microcomputador TIPO II",
  "Microcomputador TIPO III",
  "Microcomputador TIPO IV",
  "Nobreak Tipo I",
  "Nobreak Tipo II",
  "Monitor Tipo II",
  "Monitor Tipo III e IV",
] as const;

/** Inclui um valor legado (já gravado no banco) na lista de opções, sem duplicar. */
export function comValorAtual(opcoes: readonly string[], atual?: string | null): string[] {
  const v = (atual ?? "").trim();
  if (!v || opcoes.some((o) => o.toLowerCase() === v.toLowerCase())) return [...opcoes];
  return [...opcoes, v];
}

const SEM_SOFTWARE_REGEX = /(nobreak|no[\s-]?break|monitor)/i;

/**
 * Retorna true para tipos/categorias de ativos que não possuem software nem licenças
 * (ex.: Nobreak e Monitor), não devendo receber licenças nem alertas de "sem EDR".
 */
export function isAtivoSemSoftware(
  ativo?: { tipo?: string | null; categoria?: string | null } | null,
): boolean {
  if (!ativo) return false;
  return SEM_SOFTWARE_REGEX.test(`${ativo.tipo ?? ""} ${ativo.categoria ?? ""}`);
}

export const ATIVOS_SEM_SOFTWARE_OR_FILTER =
  "tipo.ilike.%nobreak%,tipo.ilike.%no-break%,tipo.ilike.%no break%,tipo.ilike.%monitor%,categoria.ilike.%nobreak%,categoria.ilike.%no-break%,categoria.ilike.%no break%,categoria.ilike.%monitor%";
