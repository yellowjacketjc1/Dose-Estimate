
export interface RadionuclideDacEntry {
  key: string; // Unique identifier, e.g., "Am-241" or "custom"
  displayName: string; // User-friendly name, e.g., "Americium-241 (Am-241)" or "Custom/Other"
  dac?: number; // DAC in µCi/cm³. Undefined for "custom" type.
}

// DAC values are typically from 10 CFR 835, Appendix A, Table 1, Inhalation DAC (Stochastic)
// Units: µCi/ml, which is equivalent to µCi/cm³
// The most conservative (smallest) DAC value is chosen when multiple absorption types (F,M,S) are listed.
export const RADIONUCLIDE_DAC_LIST: RadionuclideDacEntry[] = [
  { key: "custom", displayName: "Custom/Other" },
  // Ac - Actinium
  { key: "Ac-225", displayName: "Actinium-225 (Ac-225)", dac: 4e-13 },
  { key: "Ac-227", displayName: "Actinium-227 (Ac-227)", dac: 2e-13 },
  { key: "Ac-228", displayName: "Actinium-228 (Ac-228)", dac: 3e-10 },
  // Ag - Silver
  { key: "Ag-105", displayName: "Silver-105 (Ag-105)", dac: 2e-8 },
  { key: "Ag-108m", displayName: "Silver-108m (Ag-108m)", dac: 4e-9 },
  { key: "Ag-110m", displayName: "Silver-110m (Ag-110m)", dac: 2e-9 },
  { key: "Ag-111", displayName: "Silver-111 (Ag-111)", dac: 9e-9 },
  // Al - Aluminum
  { key: "Al-26", displayName: "Aluminum-26 (Al-26)", dac: 1e-10 },
  // Am - Americium
  { key: "Am-241", displayName: "Americium-241 (Am-241)", dac: 5e-12 },
  { key: "Am-242m", displayName: "Americium-242m (Am-242m)", dac: 2e-12 },
  { key: "Am-243", displayName: "Americium-243 (Am-243)", dac: 2e-12 },
  // As - Arsenic
  { key: "As-73", displayName: "Arsenic-73 (As-73)", dac: 8e-9 },
  { key: "As-74", displayName: "Arsenic-74 (As-74)", dac: 3e-9 },
  { key: "As-76", displayName: "Arsenic-76 (As-76)", dac: 2e-9 },
  { key: "As-77", displayName: "Arsenic-77 (As-77)", dac: 3e-8 },
  // At - Astatine
  { key: "At-211", displayName: "Astatine-211 (At-211)", dac: 2e-9 },
  // Au - Gold
  { key: "Au-195", displayName: "Gold-195 (Au-195)", dac: 1e-7 },
  { key: "Au-198", displayName: "Gold-198 (Au-198)", dac: 2e-8 },
  { key: "Au-199", displayName: "Gold-199 (Au-199)", dac: 2e-7 },
  // Ba - Barium
  { key: "Ba-131", displayName: "Barium-131 (Ba-131)", dac: 9e-9 },
  { key: "Ba-133", displayName: "Barium-133 (Ba-133)", dac: 9e-9 },
  { key: "Ba-140", displayName: "Barium-140 (Ba-140)", dac: 4e-9 },
  // Be - Beryllium
  { key: "Be-7", displayName: "Beryllium-7 (Be-7)", dac: 2e-7 },
  { key: "Be-10", displayName: "Beryllium-10 (Be-10)", dac: 1e-9 },
  // Bi - Bismuth
  { key: "Bi-207", displayName: "Bismuth-207 (Bi-207)", dac: 5e-9 },
  { key: "Bi-210", displayName: "Bismuth-210 (Bi-210)", dac: 2e-8 }, // Note: Pb-210 (parent of Po-210) is 4e-12, Po-210 is 3e-11. This is for Bi-210 itself.
  { key: "Bi-212", displayName: "Bismuth-212 (Bi-212)", dac: 9e-10 },
  { key: "Bi-213", displayName: "Bismuth-213 (Bi-213)", dac: 8e-10 },
  { key: "Bi-214", displayName: "Bismuth-214 (Bi-214)", dac: 2e-10 },
  // Bk - Berkelium
  { key: "Bk-247", displayName: "Berkelium-247 (Bk-247)", dac: 2e-12 },
  { key: "Bk-249", displayName: "Berkelium-249 (Bk-249)", dac: 3e-10 },
  // Br - Bromine
  { key: "Br-77", displayName: "Bromine-77 (Br-77)", dac: 9e-8 },
  { key: "Br-82", displayName: "Bromine-82 (Br-82)", dac: 9e-9 },
  // C - Carbon
  { key: "C-11", displayName: "Carbon-11 (C-11, Labeled Compounds)", dac: 4e-6 },
  { key: "C-14", displayName: "Carbon-14 (C-14, Labeled Compounds)", dac: 9e-7 },
  // Ca - Calcium
  { key: "Ca-41", displayName: "Calcium-41 (Ca-41)", dac: 2e-7 },
  { key: "Ca-45", displayName: "Calcium-45 (Ca-45)", dac: 2e-8 },
  { key: "Ca-47", displayName: "Calcium-47 (Ca-47)", dac: 2e-8 },
  // Cd - Cadmium
  { key: "Cd-109", displayName: "Cadmium-109 (Cd-109)", dac: 3e-9 },
  { key: "Cd-113m", displayName: "Cadmium-113m (Cd-113m)", dac: 9e-10 },
  { key: "Cd-115", displayName: "Cadmium-115 (Cd-115)", dac: 1e-8 },
  { key: "Cd-115m", displayName: "Cadmium-115m (Cd-115m)", dac: 2e-9 },
  // Ce - Cerium
  { key: "Ce-139", displayName: "Cerium-139 (Ce-139)", dac: 1e-8 },
  { key: "Ce-141", displayName: "Cerium-141 (Ce-141)", dac: 9e-9 },
  { key: "Ce-143", displayName: "Cerium-143 (Ce-143)", dac: 2e-8 },
  { key: "Ce-144", displayName: "Cerium-144 (Ce-144)", dac: 2e-10 },
  // Cf - Californium
  { key: "Cf-248", displayName: "Californium-248 (Cf-248)", dac: 2e-11 },
  { key: "Cf-249", displayName: "Californium-249 (Cf-249)", dac: 2e-12 },
  { key: "Cf-250", displayName: "Californium-250 (Cf-250)", dac: 8e-12 },
  { key: "Cf-251", displayName: "Californium-251 (Cf-251)", dac: 2e-12 },
  { key: "Cf-252", displayName: "Californium-252 (Cf-252)", dac: 1e-11 },
  { key: "Cf-254", displayName: "Californium-254 (Cf-254)", dac: 3e-11 },
  // Cl - Chlorine
  { key: "Cl-36", displayName: "Chlorine-36 (Cl-36)", dac: 2e-8 },
  { key: "Cl-38", displayName: "Chlorine-38 (Cl-38)", dac: 3e-8 },
  // Cm - Curium
  { key: "Cm-240", displayName: "Curium-240 (Cm-240)", dac: 2e-11 },
  { key: "Cm-241", displayName: "Curium-241 (Cm-241)", dac: 2e-10 },
  { key: "Cm-242", displayName: "Curium-242 (Cm-242)", dac: 9e-12 },
  { key: "Cm-243", displayName: "Curium-243 (Cm-243)", dac: 3e-12 },
  { key: "Cm-244", displayName: "Curium-244 (Cm-244)", dac: 4e-12 },
  { key: "Cm-245", displayName: "Curium-245 (Cm-245)", dac: 2e-12 },
  { key: "Cm-246", displayName: "Curium-246 (Cm-246)", dac: 2e-12 },
  { key: "Cm-247", displayName: "Curium-247 (Cm-247)", dac: 2e-12 },
  { key: "Cm-248", displayName: "Curium-248 (Cm-248)", dac: 2e-13 },
  // Co - Cobalt
  { key: "Co-56", displayName: "Cobalt-56 (Co-56)", dac: 9e-10 },
  { key: "Co-57", displayName: "Cobalt-57 (Co-57)", dac: 3e-8 },
  { key: "Co-58", displayName: "Cobalt-58 (Co-58)", dac: 3e-9 },
  { key: "Co-58m", displayName: "Cobalt-58m (Co-58m)", dac: 4e-7 },
  { key: "Co-60", displayName: "Cobalt-60 (Co-60)", dac: 2e-9 },
  // Cr - Chromium
  { key: "Cr-51", displayName: "Chromium-51 (Cr-51)", dac: 4e-7 },
  // Cs - Cesium
  { key: "Cs-129", displayName: "Cesium-129 (Cs-129)", dac: 3e-7 },
  { key: "Cs-131", displayName: "Cesium-131 (Cs-131)", dac: 2e-6 },
  { key: "Cs-132", displayName: "Cesium-132 (Cs-132)", dac: 2e-8 },
  { key: "Cs-134", displayName: "Cesium-134 (Cs-134)", dac: 3e-9 },
  { key: "Cs-135", displayName: "Cesium-135 (Cs-135)", dac: 2e-8 },
  { key: "Cs-136", displayName: "Cesium-136 (Cs-136)", dac: 9e-9 },
  { key: "Cs-137", displayName: "Cesium-137 (Cs-137)", dac: 6e-9 }, // Includes Ba-137m
  // Cu - Copper
  { key: "Cu-64", displayName: "Copper-64 (Cu-64)", dac: 8e-8 },
  { key: "Cu-67", displayName: "Copper-67 (Cu-67)", dac: 8e-8 },
  // Dy - Dysprosium
  { key: "Dy-159", displayName: "Dysprosium-159 (Dy-159)", dac: 1e-7 },
  { key: "Dy-165", displayName: "Dysprosium-165 (Dy-165)", dac: 6e-7 },
  { key: "Dy-166", displayName: "Dysprosium-166 (Dy-166)", dac: 2e-9 },
  // Er - Erbium
  { key: "Er-169", displayName: "Erbium-169 (Er-169)", dac: 1e-7 },
  { key: "Er-171", displayName: "Erbium-171 (Er-171)", dac: 1e-7 },
  // Es - Einsteinium
  { key: "Es-253", displayName: "Einsteinium-253 (Es-253)", dac: 1e-10 },
  { key: "Es-254", displayName: "Einsteinium-254 (Es-254)", dac: 3e-11 },
  { key: "Es-254m", displayName: "Einsteinium-254m (Es-254m)", dac: 4e-10 },
  // Eu - Europium
  { key: "Eu-147", displayName: "Europium-147 (Eu-147)", dac: 9e-9 },
  { key: "Eu-148", displayName: "Europium-148 (Eu-148)", dac: 2e-9 },
  { key: "Eu-149", displayName: "Europium-149 (Eu-149)", dac: 5e-8 },
  { key: "Eu-150-12h", displayName: "Europium-150 (12.6h) (Eu-150)", dac: 2e-8 },
  { key: "Eu-150-34y", displayName: "Europium-150 (34.2y) (Eu-150)", dac: 2e-9 },
  { key: "Eu-152", displayName: "Europium-152 (13.3y) (Eu-152)", dac: 9e-10 },
  { key: "Eu-152m", displayName: "Europium-152m (9.3h) (Eu-152m)", dac: 2e-7 },
  { key: "Eu-154", displayName: "Europium-154 (Eu-154)", dac: 6e-10 },
  { key: "Eu-155", displayName: "Europium-155 (Eu-155)", dac: 3e-8 },
  { key: "Eu-156", displayName: "Europium-156 (Eu-156)", dac: 2e-9 },
  // F - Fluorine
  { key: "F-18", displayName: "Fluorine-18 (F-18)", dac: 2e-6 },
  // Fe - Iron
  { key: "Fe-52", displayName: "Iron-52 (Fe-52)", dac: 5e-9 },
  { key: "Fe-55", displayName: "Iron-55 (Fe-55)", dac: 8e-8 },
  { key: "Fe-59", displayName: "Iron-59 (Fe-59)", dac: 2e-9 },
  // Fm - Fermium
  { key: "Fm-257", displayName: "Fermium-257 (Fm-257)", dac: 3e-12 },
  // Ga - Gallium
  { key: "Ga-67", displayName: "Gallium-67 (Ga-67)", dac: 2e-7 },
  { key: "Ga-72", displayName: "Gallium-72 (Ga-72)", dac: 2e-8 },
  // Gd - Gadolinium
  { key: "Gd-148", displayName: "Gadolinium-148 (Gd-148)", dac: 3e-12 },
  { key: "Gd-151", displayName: "Gadolinium-151 (Gd-151)", dac: 3e-8 },
  { key: "Gd-153", displayName: "Gadolinium-153 (Gd-153)", dac: 5e-8 },
  { key: "Gd-159", displayName: "Gadolinium-159 (Gd-159)", dac: 4e-8 },
  // Ge - Germanium
  { key: "Ge-68", displayName: "Germanium-68 (Ge-68)", dac: 3e-9 },
  { key: "Ge-71", displayName: "Germanium-71 (Ge-71)", dac: 1e-6 },
  // H - Hydrogen (Tritium)
  { key: "H-3", displayName: "Tritium (H-3, Oxide)", dac: 2e-5 },
  // Hf - Hafnium
  { key: "Hf-172", displayName: "Hafnium-172 (Hf-172)", dac: 9e-11 },
  { key: "Hf-175", displayName: "Hafnium-175 (Hf-175)", dac: 8e-9 },
  { key: "Hf-181", displayName: "Hafnium-181 (Hf-181)", dac: 6e-9 },
  // Hg - Mercury
  { key: "Hg-197", displayName: "Mercury-197 (Hg-197)", dac: 1e-7 }, // Hg-197m is 1e-7, Hg-197 is 3e-7, choosing smaller
  { key: "Hg-203", displayName: "Mercury-203 (Hg-203)", dac: 7e-9 },
  // Ho - Holmium
  { key: "Ho-166", displayName: "Holmium-166 (Ho-166)", dac: 3e-8 },
  { key: "Ho-166m", displayName: "Holmium-166m (Ho-166m)", dac: 3e-11 },
  // I - Iodine
  { key: "I-123", displayName: "Iodine-123 (I-123)", dac: 2e-7 },
  { key: "I-124", displayName: "Iodine-124 (I-124)", dac: 7e-10 },
  { key: "I-125", displayName: "Iodine-125 (I-125)", dac: 4e-9 },
  { key: "I-126", displayName: "Iodine-126 (I-126)", dac: 2e-10 },
  { key: "I-129", displayName: "Iodine-129 (I-129)", dac: 4e-10 },
  { key: "I-131", displayName: "Iodine-131 (I-131)", dac: 2e-9 },
  { key: "I-132", displayName: "Iodine-132 (I-132)", dac: 4e-8 },
  { key: "I-133", displayName: "Iodine-133 (I-133)", dac: 9e-9 },
  { key: "I-134", displayName: "Iodine-134 (I-134)", dac: 2e-7 },
  { key: "I-135", displayName: "Iodine-135 (I-135)", dac: 2e-8 },
  // In - Indium
  { key: "In-111", displayName: "Indium-111 (In-111)", dac: 1e-7 },
  { key: "In-113m", displayName: "Indium-113m (In-113m)", dac: 1e-6 },
  { key: "In-114m", displayName: "Indium-114m (In-114m)", dac: 8e-10 },
  { key: "In-115m", displayName: "Indium-115m (In-115m)", dac: 1e-6 },
  // Ir - Iridium
  { key: "Ir-190", displayName: "Iridium-190 (Ir-190)", dac: 9e-9 },
  { key: "Ir-192", displayName: "Iridium-192 (Ir-192)", dac: 6e-9 },
  { key: "Ir-194m", displayName: "Iridium-194m (Ir-194m)", dac: 1e-7 },
  // K - Potassium
  { key: "K-40", displayName: "Potassium-40 (K-40)", dac: 1e-8 },
  { key: "K-42", displayName: "Potassium-42 (K-42)", dac: 3e-8 },
  { key: "K-43", displayName: "Potassium-43 (K-43)", dac: 1e-8 },
  // La - Lanthanum
  { key: "La-140", displayName: "Lanthanum-140 (La-140)", dac: 9e-9 },
  // Lu - Lutetium
  { key: "Lu-172", displayName: "Lutetium-172 (Lu-172)", dac: 2e-9 },
  { key: "Lu-173", displayName: "Lutetium-173 (Lu-173)", dac: 3e-8 },
  { key: "Lu-174", displayName: "Lutetium-174 (Lu-174)", dac: 3e-8 },
  { key: "Lu-174m", displayName: "Lutetium-174m (Lu-174m)", dac: 2e-7 },
  { key: "Lu-177", displayName: "Lutetium-177 (Lu-177)", dac: 4e-8 },
  // Md - Mendelevium
  { key: "Md-258", displayName: "Mendelevium-258 (Md-258)", dac: 9e-11 },
  // Mg - Magnesium
  { key: "Mg-28", displayName: "Magnesium-28 (Mg-28)", dac: 6e-9 },
  // Mn - Manganese
  { key: "Mn-52", displayName: "Manganese-52 (Mn-52)", dac: 3e-8 },
  { key: "Mn-53", displayName: "Manganese-53 (Mn-53)", dac: 1e-6 },
  { key: "Mn-54", displayName: "Manganese-54 (Mn-54)", dac: 9e-9 },
  { key: "Mn-56", displayName: "Manganese-56 (Mn-56)", dac: 1e-7 },
  // Mo - Molybdenum
  { key: "Mo-99", displayName: "Molybdenum-99 (Mo-99)", dac: 8e-8 },
  // Na - Sodium
  { key: "Na-22", displayName: "Sodium-22 (Na-22)", dac: 2e-9 },
  { key: "Na-24", displayName: "Sodium-24 (Na-24)", dac: 2e-8 },
  // Nb - Niobium
  { key: "Nb-93m", displayName: "Niobium-93m (Nb-93m)", dac: 3e-7 },
  { key: "Nb-94", displayName: "Niobium-94 (Nb-94)", dac: 7e-10 },
  { key: "Nb-95", displayName: "Niobium-95 (Nb-95)", dac: 6e-9 },
  // Nd - Neodymium
  { key: "Nd-147", displayName: "Neodymium-147 (Nd-147)", dac: 3e-8 },
  { key: "Nd-149", displayName: "Neodymium-149 (Nd-149)", dac: 3e-7 },
  // Ni - Nickel
  { key: "Ni-59", displayName: "Nickel-59 (Ni-59)", dac: 2e-7 },
  { key: "Ni-63", displayName: "Nickel-63 (Ni-63)", dac: 8e-8 },
  { key: "Ni-65", displayName: "Nickel-65 (Ni-65)", dac: 1e-7 },
  // Np - Neptunium
  { key: "Np-235", displayName: "Neptunium-235 (Np-235)", dac: 4e-8 },
  { key: "Np-236-long", displayName: "Neptunium-236 (1.15E5 y) (Np-236)", dac: 2e-11 },
  { key: "Np-236-short", displayName: "Neptunium-236 (22.5 h) (Np-236)", dac: 2e-7 },
  { key: "Np-237", displayName: "Neptunium-237 (Np-237)", dac: 3e-13 },
  { key: "Np-239", displayName: "Neptunium-239 (Np-239)", dac: 9e-8 },
  // Os - Osmium
  { key: "Os-185", displayName: "Osmium-185 (Os-185)", dac: 4e-8 },
  { key: "Os-191", displayName: "Osmium-191 (Os-191)", dac: 2e-7 },
  { key: "Os-191m", displayName: "Osmium-191m (Os-191m)", dac: 2e-5 },
  { key: "Os-193", displayName: "Osmium-193 (Os-193)", dac: 2e-8 },
  // P - Phosphorus
  { key: "P-32", displayName: "Phosphorus-32 (P-32)", dac: 9e-9 },
  { key: "P-33", displayName: "Phosphorus-33 (P-33)", dac: 3e-8 },
  // Pa - Protactinium
  { key: "Pa-230", displayName: "Protactinium-230 (Pa-230)", dac: 3e-11 },
  { key: "Pa-231", displayName: "Protactinium-231 (Pa-231)", dac: 4e-13 },
  { key: "Pa-233", displayName: "Protactinium-233 (Pa-233)", dac: 2e-9 },
  // Pb - Lead
  { key: "Pb-203", displayName: "Lead-203 (Pb-203)", dac: 2e-7 },
  { key: "Pb-205", displayName: "Lead-205 (Pb-205)", dac: 1e-8 },
  { key: "Pb-210", displayName: "Lead-210 (Pb-210)", dac: 4e-12 },
  { key: "Pb-212", displayName: "Lead-212 (Pb-212)", dac: 2e-10 },
  // Pd - Palladium
  { key: "Pd-103", displayName: "Palladium-103 (Pd-103)", dac: 2e-7 },
  { key: "Pd-107", displayName: "Palladium-107 (Pd-107)", dac: 1e-7 },
  { key: "Pd-109", displayName: "Palladium-109 (Pd-109)", dac: 2e-7 },
  // Pm - Promethium
  { key: "Pm-143", displayName: "Promethium-143 (Pm-143)", dac: 2e-8 },
  { key: "Pm-144", displayName: "Promethium-144 (Pm-144)", dac: 2e-9 },
  { key: "Pm-145", displayName: "Promethium-145 (Pm-145)", dac: 4e-8 },
  { key: "Pm-147", displayName: "Promethium-147 (Pm-147)", dac: 3e-9 },
  { key: "Pm-148", displayName: "Promethium-148 (Pm-148)", dac: 8e-10 },
  { key: "Pm-148m", displayName: "Promethium-148m (Pm-148m)", dac: 4e-10 },
  { key: "Pm-149", displayName: "Promethium-149 (Pm-149)", dac: 2e-7 },
  { key: "Pm-151", displayName: "Promethium-151 (Pm-151)", dac: 1e-7 },
  // Po - Polonium
  { key: "Po-210", displayName: "Polonium-210 (Po-210)", dac: 3e-11 },
  // Pr - Praseodymium
  { key: "Pr-142", displayName: "Praseodymium-142 (Pr-142)", dac: 2e-8 },
  { key: "Pr-143", displayName: "Praseodymium-143 (Pr-143)", dac: 9e-9 },
  // Pt - Platinum
  { key: "Pt-191", displayName: "Platinum-191 (Pt-191)", dac: 1e-7 },
  { key: "Pt-193", displayName: "Platinum-193 (Pt-193)", dac: 8e-7 },
  { key: "Pt-193m", displayName: "Platinum-193m (Pt-193m)", dac: 5e-7 },
  { key: "Pt-197", displayName: "Platinum-197 (Pt-197)", dac: 5e-7 },
  // Pu - Plutonium
  { key: "Pu-236", displayName: "Plutonium-236 (Pu-236)", dac: 2e-11 },
  { key: "Pu-237", displayName: "Plutonium-237 (Pu-237)", dac: 5e-8 },
  { key: "Pu-238", displayName: "Plutonium-238 (Pu-238)", dac: 3e-12 },
  { key: "Pu-239", displayName: "Plutonium-239 (Pu-239)", dac: 2e-12 },
  { key: "Pu-240", displayName: "Plutonium-240 (Pu-240)", dac: 2e-12 },
  { key: "Pu-241", displayName: "Plutonium-241 (Pu-241)", dac: 1e-10 },
  { key: "Pu-242", displayName: "Plutonium-242 (Pu-242)", dac: 2e-12 },
  { key: "Pu-244", displayName: "Plutonium-244 (Pu-244)", dac: 2e-12 },
  // Ra - Radium
  { key: "Ra-223", displayName: "Radium-223 (Ra-223)", dac: 3e-11 },
  { key: "Ra-224", displayName: "Radium-224 (Ra-224)", dac: 1e-10 },
  { key: "Ra-225", displayName: "Radium-225 (Ra-225)", dac: 5e-11 },
  { key: "Ra-226", displayName: "Radium-226 (Ra-226)", dac: 3e-11 },
  { key: "Ra-228", displayName: "Radium-228 (Ra-228)", dac: 2e-11 },
  // Rb - Rubidium
  { key: "Rb-86", displayName: "Rubidium-86 (Rb-86)", dac: 2e-9 },
  { key: "Rb-87", displayName: "Rubidium-87 (Rb-87)", dac: 2e-8 },
  // Re - Rhenium
  { key: "Re-186", displayName: "Rhenium-186 (Re-186)", dac: 1e-7 },
  { key: "Re-187", displayName: "Rhenium-187 (Re-187)", dac: 2e-6 },
  { key: "Re-188", displayName: "Rhenium-188 (Re-188)", dac: 2e-7 },
  // Rh - Rhodium
  { key: "Rh-99", displayName: "Rhodium-99 (Rh-99)", dac: 4e-8 },
  { key: "Rh-102", displayName: "Rhodium-102 (Rh-102)", dac: 5e-10 },
  { key: "Rh-102m", displayName: "Rhodium-102m (Rh-102m)", dac: 2e-9 },
  { key: "Rh-103m", displayName: "Rhodium-103m (Rh-103m)", dac: 3e-5 },
  { key: "Rh-105", displayName: "Rhodium-105 (Rh-105)", dac: 2e-7 },
  // Ru - Ruthenium
  { key: "Ru-97", displayName: "Ruthenium-97 (Ru-97)", dac: 2e-7 },
  { key: "Ru-103", displayName: "Ruthenium-103 (Ru-103)", dac: 4e-9 },
  { key: "Ru-105", displayName: "Ruthenium-105 (Ru-105)", dac: 2e-7 },
  { key: "Ru-106", displayName: "Ruthenium-106 (Ru-106)", dac: 2e-10 },
  // S - Sulfur
  { key: "S-35", displayName: "Sulfur-35 (S-35, Elemental/Other)", dac: 8e-9 }, // Vapor is 2E-7
  // Sb - Antimony
  { key: "Sb-122", displayName: "Antimony-122 (Sb-122)", dac: 2e-8 },
  { key: "Sb-124", displayName: "Antimony-124 (Sb-124)", dac: 2e-9 },
  { key: "Sb-125", displayName: "Antimony-125 (Sb-125)", dac: 6e-9 },
  // Sc - Scandium
  { key: "Sc-44", displayName: "Scandium-44 (Sc-44)", dac: 1e-7 },
  { key: "Sc-46", displayName: "Scandium-46 (Sc-46)", dac: 2e-9 },
  { key: "Sc-47", displayName: "Scandium-47 (Sc-47)", dac: 2e-7 },
  { key: "Sc-48", displayName: "Scandium-48 (Sc-48)", dac: 8e-9 },
  // Se - Selenium
  { key: "Se-75", displayName: "Selenium-75 (Se-75)", dac: 6e-9 },
  { key: "Se-79", displayName: "Selenium-79 (Se-79)", dac: 6e-9 },
  // Si - Silicon
  { key: "Si-31", displayName: "Silicon-31 (Si-31)", dac: 2e-7 },
  { key: "Si-32", displayName: "Silicon-32 (Si-32)", dac: 9e-11 },
  // Sm - Samarium
  { key: "Sm-147", displayName: "Samarium-147 (Sm-147)", dac: 3e-12 },
  { key: "Sm-151", displayName: "Samarium-151 (Sm-151)", dac: 2e-8 },
  { key: "Sm-153", displayName: "Samarium-153 (Sm-153)", dac: 9e-8 },
  // Sn - Tin
  { key: "Sn-113", displayName: "Tin-113 (Sn-113)", dac: 9e-9 },
  { key: "Sn-123", displayName: "Tin-123 (Sn-123)", dac: 3e-9 },
  { key: "Sn-126", displayName: "Tin-126 (Sn-126)", dac: 9e-11 },
  // Sr - Strontium
  { key: "Sr-82", displayName: "Strontium-82 (Sr-82)", dac: 3e-10 },
  { key: "Sr-85", displayName: "Strontium-85 (Sr-85)", dac: 6e-9 },
  { key: "Sr-89", displayName: "Strontium-89 (Sr-89)", dac: 1e-8 },
  { key: "Sr-90", displayName: "Strontium-90 (Sr-90)", dac: 1e-9 }, // Includes Y-90
  { key: "Sr-91", displayName: "Strontium-91 (Sr-91)", dac: 9e-9 },
  { key: "Sr-92", displayName: "Strontium-92 (Sr-92)", dac: 1e-8 },
  // Ta - Tantalum
  { key: "Ta-178", displayName: "Tantalum-178 (Ta-178)", dac: 1e-6 },
  { key: "Ta-179", displayName: "Tantalum-179 (Ta-179)", dac: 2e-6 },
  { key: "Ta-182", displayName: "Tantalum-182 (Ta-182)", dac: 6e-10 },
  // Tb - Terbium
  { key: "Tb-157", displayName: "Terbium-157 (Tb-157)", dac: 3e-8 },
  { key: "Tb-158", displayName: "Terbium-158 (Tb-158)", dac: 5e-10 },
  { key: "Tb-160", displayName: "Terbium-160 (Tb-160)", dac: 3e-9 },
  // Tc - Technetium
  { key: "Tc-95m", displayName: "Technetium-95m (Tc-95m)", dac: 2e-7 },
  { key: "Tc-96", displayName: "Technetium-96 (Tc-96)", dac: 6e-8 },
  { key: "Tc-96m", displayName: "Technetium-96m (Tc-96m)", dac: 2e-6 },
  { key: "Tc-97", displayName: "Technetium-97 (Tc-97)", dac: 2e-6 },
  { key: "Tc-97m", displayName: "Technetium-97m (Tc-97m)", dac: 3e-7 },
  { key: "Tc-98", displayName: "Technetium-98 (Tc-98)", dac: 9e-10 },
  { key: "Tc-99", displayName: "Technetium-99 (Tc-99)", dac: 2e-7 },
  { key: "Tc-99m", displayName: "Technetium-99m (Tc-99m)", dac: 2e-6 },
  // Te - Tellurium
  { key: "Te-123m", displayName: "Tellurium-123m (Te-123m)", dac: 9e-9 },
  { key: "Te-125m", displayName: "Tellurium-125m (Te-125m)", dac: 2e-8 },
  { key: "Te-127", displayName: "Tellurium-127 (Te-127)", dac: 2e-7 },
  { key: "Te-127m", displayName: "Tellurium-127m (Te-127m)", dac: 4e-9 },
  { key: "Te-129", displayName: "Tellurium-129 (Te-129)", dac: 6e-7 },
  { key: "Te-129m", displayName: "Tellurium-129m (Te-129m)", dac: 6e-9 },
  { key: "Te-131m", displayName: "Tellurium-131m (Te-131m)", dac: 2e-8 },
  { key: "Te-132", displayName: "Tellurium-132 (Te-132)", dac: 3e-9 },
  // Th - Thorium
  { key: "Th-Nat", displayName: "Thorium-Natural (Th-Nat)", dac: 3e-13 }, // Covers Th-232, Th-228, etc. in equilibrium
  { key: "Th-228", displayName: "Thorium-228 (Th-228)", dac: 2e-12 },
  { key: "Th-229", displayName: "Thorium-229 (Th-229)", dac: 8e-14 },
  { key: "Th-230", displayName: "Thorium-230 (Th-230)", dac: 3e-13 },
  { key: "Th-232", displayName: "Thorium-232 (Th-232)", dac: 4e-13 },
  { key: "Th-234", displayName: "Thorium-234 (Th-234)", dac: 2e-9 },
  // Ti - Titanium
  { key: "Ti-44", displayName: "Titanium-44 (Ti-44)", dac: 8e-11 },
  // Tl - Thallium
  { key: "Tl-200", displayName: "Thallium-200 (Tl-200)", dac: 2e-7 },
  { key: "Tl-201", displayName: "Thallium-201 (Tl-201)", dac: 4e-7 },
  { key: "Tl-202", displayName: "Thallium-202 (Tl-202)", dac: 8e-8 },
  { key: "Tl-204", displayName: "Thallium-204 (Tl-204)", dac: 4e-8 },
  // Tm - Thulium
  { key: "Tm-167", displayName: "Thulium-167 (Tm-167)", dac: 8e-8 },
  { key: "Tm-170", displayName: "Thulium-170 (Tm-170)", dac: 2e-9 },
  { key: "Tm-171", displayName: "Thulium-171 (Tm-171)", dac: 3e-7 },
  // U - Uranium
  { key: "U-Nat", displayName: "Uranium-Natural (U-Nat)", dac: 5e-12 },
  { key: "U-230", displayName: "Uranium-230 (U-230)", dac: 8e-13 },
  { key: "U-232", displayName: "Uranium-232 (U-232)", dac: 3e-13 },
  { key: "U-233", displayName: "Uranium-233 (U-233)", dac: 5e-12 },
  { key: "U-234", displayName: "Uranium-234 (U-234)", dac: 6e-12 },
  { key: "U-235", displayName: "Uranium-235 (U-235)", dac: 5e-12 },
  { key: "U-236", displayName: "Uranium-236 (U-236)", dac: 5e-12 },
  { key: "U-238", displayName: "Uranium-238 (U-238)", dac: 5e-12 },
  // V - Vanadium
  { key: "V-48", displayName: "Vanadium-48 (V-48)", dac: 9e-9 },
  { key: "V-49", displayName: "Vanadium-49 (V-49)", dac: 1e-6 },
  // W - Tungsten
  { key: "W-181", displayName: "Tungsten-181 (W-181)", dac: 4e-7 },
  { key: "W-185", displayName: "Tungsten-185 (W-185)", dac: 2e-7 },
  { key: "W-187", displayName: "Tungsten-187 (W-187)", dac: 2e-7 },
  // Y - Yttrium
  { key: "Y-88", displayName: "Yttrium-88 (Y-88)", dac: 9e-10 },
  { key: "Y-90", displayName: "Yttrium-90 (Y-90)", dac: 6e-9 },
  { key: "Y-91", displayName: "Yttrium-91 (Y-91)", dac: 4e-9 },
  { key: "Y-91m", displayName: "Yttrium-91m (Y-91m)", dac: 5e-6 },
  { key: "Y-92", displayName: "Yttrium-92 (Y-92)", dac: 2e-8 },
  { key: "Y-93", displayName: "Yttrium-93 (Y-93)", dac: 9e-9 },
  // Yb - Ytterbium
  { key: "Yb-169", displayName: "Ytterbium-169 (Yb-169)", dac: 3e-8 },
  { key: "Yb-175", displayName: "Ytterbium-175 (Yb-175)", dac: 2e-7 },
  // Zn - Zinc
  { key: "Zn-65", displayName: "Zinc-65 (Zn-65)", dac: 9e-10 },
  { key: "Zn-69", displayName: "Zinc-69 (Zn-69)", dac: 3e-7 },
  { key: "Zn-69m", displayName: "Zinc-69m (Zn-69m)", dac: 6e-8 },
  // Zr - Zirconium
  { key: "Zr-93", displayName: "Zirconium-93 (Zr-93)", dac: 2e-8 },
  { key: "Zr-95", displayName: "Zirconium-95 (Zr-95)", dac: 2e-9 },
  { key: "Zr-97", displayName: "Zirconium-97 (Zr-97)", dac: 1e-8 },
];
