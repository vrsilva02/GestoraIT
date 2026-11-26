import { describe, it, expect } from "vitest";
import { isAtivoSemSoftware } from "./ativos-opcoes";

describe("isAtivoSemSoftware", () => {
  it("identifica nobreaks e monitores pelo tipo ou categoria", () => {
    expect(isAtivoSemSoftware({ tipo: "MONITOR" })).toBe(true);
    expect(isAtivoSemSoftware({ tipo: "NOBREAK 600VA" })).toBe(true);
    expect(isAtivoSemSoftware({ tipo: "NOBREAK 1200VA" })).toBe(true);
    expect(isAtivoSemSoftware({ tipo: "No-break 1500VA" })).toBe(true);
    expect(isAtivoSemSoftware({ categoria: "Nobreak Tipo I" })).toBe(true);
    expect(isAtivoSemSoftware({ categoria: "Monitor Tipo II" })).toBe(true);
    expect(isAtivoSemSoftware({ categoria: "Monitor Tipo III e IV" })).toBe(true);
  });

  it("permite software e EDR em notebooks, desktops, servidores e afins", () => {
    expect(isAtivoSemSoftware({ tipo: "NOTEBOOK", categoria: "Notebook" })).toBe(false);
    expect(isAtivoSemSoftware({ tipo: "DESKTOP", categoria: "Microcomputador TIPO I" })).toBe(false);
    expect(isAtivoSemSoftware({ tipo: "MINI PC" })).toBe(false);
    expect(isAtivoSemSoftware({ tipo: "WORKSTATION" })).toBe(false);
    expect(isAtivoSemSoftware({ tipo: "MACBOOK" })).toBe(false);
    expect(isAtivoSemSoftware({ tipo: null, categoria: null })).toBe(false);
    expect(isAtivoSemSoftware(null)).toBe(false);
  });
});
