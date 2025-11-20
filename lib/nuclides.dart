// Shared Nuclide Data
// Values are DAC in µCi/mL

class NuclideData {
  static const Map<String, double> dacValues = {
    // A
    "Ac-227": 2e-13, // (BS/BS/St)
    "Ag-108m": 2e-8, // (S)
    "Ag-110m": 7e-8, // (S)
    "Al-26": 4e-8, // (F/M)
    "Am-241": 5e-12,
    "Am-243": 5e-12,
    "Ar-37": 3.0, // (Immersion)
    "Ar-39": 1e-3, // (Immersion)
    "Ar-41": 3e-6, // (Immersion)
    "As-73": 8e-7,
    "As-74": 3e-7,
    "As-76": 6e-7,
    "As-77": 1e-6,
    "At-211": 5e-9, // (M)
    "Au-195": 4e-7, // (S)
    "Au-198": 5e-7, // (F/S)
    "Au-199": 7e-7, // (S)

    // B
    "Ba-131": 1e-6,
    "Ba-133": 3e-7,
    "Ba-140": 3e-7,
    "Be-7": 1e-5, // (M/S)
    "Be-10": 2e-8, // (S)
    "Bi-206": 2e-7, // (F/M)
    "Bi-207": 1e-7, // (M)
    "Bi-210": 9e-9, // (M)
    "Bi-212": 8e-9, // (M)
    "Bk-249": 1e-9,
    "Br-82": 3e-7, // (F/M)

    // C
    "C-11": 1e-4, // (Vapor)
    "C-14": 9e-7, // (Vapor)
    "Ca-41": 2e-6,
    "Ca-45": 2e-7,
    "Ca-47": 2e-7,
    "Cd-109": 2e-8, // (M)
    "Cd-113m": 1e-9, // (F)
    "Cd-115": 4e-7, // (F/S)
    "Cd-115m": 3e-8, // (F)
    "Ce-139": 4e-7,
    "Ce-141": 1e-7, // (M/S)
    "Ce-143": 5e-7, // (M/S)
    "Ce-144": 1e-8, // (S)
    "Cf-249": 3e-12,
    "Cf-250": 7e-12,
    "Cf-251": 3e-12,
    "Cf-252": 1e-11,
    "Cl-36": 1e-7, // (M)
    "Cl-38": 5e-6, // (M)
    "Cm-242": 1e-10,
    "Cm-243": 7e-12,
    "Cm-244": 9e-12,
    "Cm-245": 5e-12,
    "Cm-246": 5e-12,
    "Cm-247": 5e-12,
    "Cm-248": 1e-12,
    "Co-56": 1e-7, // (M/S)
    "Co-57": 9e-7, // (M)
    "Co-58": 3e-7, // (S)
    "Co-58m": 3e-5, // (M/S)
    "Co-60": 3e-8, // (S)
    "Co-60m": 4e-4, // (M/S)
    "Cr-51": 1e-5, // (F/M/S)
    "Cs-129": 2e-6,
    "Cs-131": 7e-6,
    "Cs-134": 5e-8,
    "Cs-134m": 8e-6,
    "Cs-135": 5e-7,
    "Cs-136": 2e-7,
    "Cs-137": 8e-8,
    "Cu-64": 3e-6, // (M/S)
    "Cu-67": 9e-7, // (S)

    // D
    "Dy-159": 2e-6,
    "Dy-165": 6e-6,
    "Dy-166": 3e-7,

    // E
    "Er-169": 6e-7,
    "Er-171": 1e-6,
    "Eu-152": 2e-8,
    "Eu-152m": 1e-6,
    "Eu-154": 8e-9,
    "Eu-155": 7e-8,

    // F
    "F-18": 3e-6, // (M/S)
    "Fe-52": 5e-7, // (F)
    "Fe-55": 6e-7, // (F)
    "Fe-59": 1e-7, // (F/M)

    // G
    "Ga-67": 2e-6, // (M)
    "Ga-68": 4e-6, // (M)
    "Ga-72": 5e-7, // (F/M)
    "Gd-146": 1e-7, // (F/M)
    "Gd-148": 5e-12, // (F)
    "Gd-149": 7e-7, // (M)
    "Gd-151": 2e-7, // (F)
    "Gd-153": 9e-8, // (F)
    "Gd-159": 1e-6, // (M)
    "Ge-68": 7e-8, // (M)
    "Ge-71": 5e-5, // (F/M)

    // H
    "H-3": 2e-5, // (Water)
    "Hf-172": 6e-9, // (F)
    "Hf-175": 5e-7, // (M)
    "Hf-181": 1e-7, // (F/M)
    "Hg-197": 1e-7, // (Vapor)
    "Hg-197m": 9e-8, // (Vapor)
    "Hg-203": 8e-8, // (Vapor)
    "Ho-166": 6e-7,

    // I
    "I-123": 1e-6, // (Methyl/Vapor)
    "I-124": 2e-8, // (Vapor)
    "I-125": 2e-8, // (Methyl/Vapor)
    "I-126": 1e-8, // (Methyl/Vapor)
    "I-129": 2e-9, // (Vapor)
    "I-131": 1e-8, // (Methyl/Vapor)
    "I-132": 1e-6, // (Methyl/Vapor)
    "I-133": 7e-8, // (Vapor)
    "I-134": 3e-6, // (Vapor/Particulate)
    "I-135": 3e-7, // (Vapor)
    "In-111": 1e-6, // (F/M)
    "In-113m": 1e-5, // (F/M)
    "In-114m": 5e-8, // (M)
    "In-115m": 5e-6, // (F)
    "Ir-190": 2e-7, // (M/S)
    "Ir-192": 1e-7, // (M/S)
    "Ir-194": 7e-7, // (F/S)

    // K
    "K-40": 1e-7,
    "K-42": 2e-6,
    "K-43": 9e-7,
    "Kr-74": 3e-6, // (Immersion)
    "Kr-76": 1e-5, // (Immersion)
    "Kr-77": 4e-6, // (Immersion)
    "Kr-79": 2e-5, // (Immersion)
    "Kr-81": 5e-4, // (Immersion)
    "Kr-83m": 5e-2, // (Immersion)
    "Kr-85": 5e-4, // (Immersion)
    "Kr-85m": 3e-5, // (Immersion)
    "Kr-87": 4e-6, // (Immersion)
    "Kr-88": 2e-6, // (Immersion)

    // L
    "La-137": 4e-8, // (F)
    "La-140": 3e-7, // (M)
    "Lu-172": 3e-7, // (F/M)
    "Lu-173": 2e-7, // (F)
    "Lu-174": 9e-8, // (F)
    "Lu-174m": 2e-7, // (F/M)
    "Lu-177": 5e-7, // (F/M)

    // M
    "Mn-52": 2e-7, // (F/M)
    "Mn-53": 5e-6, // (M)
    "Mn-54": 4e-7, // (F)
    "Mn-56": 2e-6, // (F/M)
    "Mo-93": 2e-7, // (F)
    "Mo-99": 5e-7, // (M)

    // N
    "Na-22": 2e-7,
    "Na-24": 4e-7,
    "Nb-93m": 6e-7, // (M)
    "Nb-94": 2e-8, // (M)
    "Nb-95": 4e-7, // (W/Y)
    "Nb-97": 5e-6, // (W/Y)
    "Nd-144": 2e-13, // Not listed in source; alpha emitter default
    "Nd-147": 2e-7, // (W/Y)
    "Nd-149": 4e-6, // (W/Y)
    "Ni-56": 4e-7, // (Inorg F/Carbonyl)
    "Ni-57": 5e-7, // (Inorg F)
    "Ni-59": 6e-7, // (Carbonyl)
    "Ni-63": 2e-7, // (Carbonyl)
    "Ni-65": 8e-7, // (Carbonyl)
    "Np-235": 1e-6,
    "Np-236": 4e-11, // (Long-lived)
    "Np-237": 8e-12,
    "Np-239": 5e-7,

    // O
    "Os-185": 5e-7, // (F/S)
    "Os-191": 3e-7, // (S)
    "Os-191m": 4e-6, // (F)
    "Os-193": 8e-7, // (M/S)

    // P
    "P-32": 1e-7, // (M)
    "P-33": 4e-7, // (M)
    "Pa-230": 9e-10, // (M)
    "Pa-231": 1e-12, // (W)
    "Pa-233": 1e-7, // (M)
    "Pb-203": 2e-6,
    "Pb-210": 1e-10,
    "Pb-212": 5e-9,
    "Pd-103": 1e-6, // (M/S)
    "Pd-107": 1e-6, // (S)
    "Pd-109": 1e-6, // (M/S)
    "Pm-143": 5e-7, // (W)
    "Pm-144": 1e-7, // (W/Y)
    "Pm-145": 1e-7, // (W)
    "Pm-147": 1e-7, // (W/Y)
    "Pm-148": 2e-7, // (W/Y)
    "Pm-148m": 1e-7, // (W/Y)
    "Pm-149": 6e-7, // (Y)
    "Pm-151": 8e-7, // (Y)
    "Po-208": 2e-13, // Not listed; alpha default
    "Po-209": 2e-13, // Not listed; alpha default
    "Po-210": 2e-10, // (M)
    "Pr-142": 7e-7, // (Y)
    "Pr-143": 2e-7, // (W/Y)
    "Pt-191": 1e-6,
    "Pt-193": 2e-5,
    "Pt-193m": 2e-6,
    "Pt-195m": 1e-6,
    "Pt-197": 3e-6,
    "Pt-197m": 7e-6,
    "Pu-236": 1e-11, // (W)
    "Pu-237": 1e-6, // (W/Y)
    "Pu-238": 6e-12, // (W)
    "Pu-239": 5e-12, // (W)
    "Pu-240": 5e-12, // (W)
    "Pu-241": 2e-10, // (W)
    "Pu-242": 5e-12, // (W)
    "Pu-244": 5e-12, // (W)

    // R
    "Ra-223": 9e-11,
    "Ra-224": 2e-10,
    "Ra-225": 1e-10,
    "Ra-226": 2e-10,
    "Ra-228": 1e-10,
    "Rb-81": 2e-6,
    "Rb-83": 5e-7,
    "Rb-84": 3e-7,
    "Rb-86": 4e-7,
    "Rb-87": 7e-7,
    "Rb-88": 1e-5,
    "Re-184": 3e-7, // (F)
    "Re-184m": 1e-7, // (M)
    "Re-186": 4e-7, // (M)
    "Re-187": 1e-4, // (M)
    "Re-188": 7e-7, // (F)
    "Re-189": 9e-7, // (M)
    "Rh-99": 6e-7, // (M/S)
    "Rh-101": 1e-7, // (S)
    "Rh-102": 6e-8, // (F)
    "Rh-102m": 1e-7, // (S)
    "Rh-103m": 2e-4, // (M/S)
    "Rh-105": 1e-6, // (F/M/S)
    "Rn-220": 1e-8, // (Includes daughters)
    "Rn-222": 8e-8, // (Includes daughters)
    "Ru-97": 2e-6, // (F/M/S)
    "Ru-103": 2e-7, // (M/S)
    "Ru-105": 2e-6, // (F/M/S)
    "Ru-106": 1e-8, // (S)

    // S
    "S-35": 5e-7, // (M)
    "Sb-122": 4e-7, // (M)
    "Sb-124": 1e-7, // (M)
    "Sb-125": 1e-7, // (M)
    "Sb-126": 1e-7, // (M)
    "Sc-44": 1e-6,
    "Sc-44m": 2e-7,
    "Sc-46": 1e-7,
    "Sc-47": 7e-7,
    "Sc-48": 2e-7,
    "Se-73": 1e-6, // (F/M)
    "Se-75": 3e-7, // (M)
    "Se-79": 1e-7, // (M)
    "Si-31": 5e-6, // (M/S)
    "Si-32": 1e-8, // (S)
    "Sm-145": 4e-7,
    "Sm-147": 2e-11,
    "Sm-151": 7e-8,
    "Sm-153": 8e-7,
    "Sn-113": 1e-7, // (M)
    "Sn-117m": 2e-7, // (F)
    "Sn-119m": 3e-7, // (F)
    "Sn-121": 2e-6, // (F)
    "Sn-121m": 1e-7, // (F)
    "Sn-123": 1e-7, // (F)
    "Sn-125": 2e-7, // (F)
    "Sn-126": 3e-8, // (M/S)
    "Sr-82": 7e-8, // (M)
    "Sr-85": 8e-7, // (M)
    "Sr-85m": 3e-5, // (M)
    "Sr-87m": 9e-6, // (M)
    "Sr-89": 1e-7, // (M)
    "Sr-90": 7e-9, // (M)
    "Sr-91": 9e-7, // (M)
    "Sr-92": 1e-6, // (M)

    // T
    "Ta-178": 3e-6,
    "Ta-179": 1e-6, // (M)
    "Ta-182": 7e-8, // (M)
    "Tb-157": 2e-7,
    "Tb-158": 1e-8,
    "Tb-160": 1e-7,
    "Tc-94": 1e-6, // (F/M)
    "Tc-94m": 4e-6, // (F)
    "Tc-95": 1e-6, // (F/M)
    "Tc-95m": 6e-7, // (F)
    "Tc-96": 3e-7, // (F/M)
    "Tc-96m": 2e-5, // (F/M)
    "Tc-97": 3e-6, // (F)
    "Tc-97m": 2e-7, // (M)
    "Tc-98": 9e-8, // (F)
    "Tc-99": 1e-7, // (M)
    "Tc-99m": 1e-5, // (F/M)
    "Te-121": 1e-7, // (Vapor/Particulate W)
    "Te-121m": 4e-8, // (Particulate Y)
    "Te-123": 1e-8, // (Vapor)
    "Te-123m": 1e-7, // (Particulate W/Y)
    "Te-125m": 1e-7, // (Vapor/Particulate Y)
    "Te-127": 3e-6, // (M)
    "Te-127m": 6e-8, // (Vapor)
    "Te-129": 7e-6, // (Y)
    "Te-129m": 1e-7, // (Particulate W/Y)
    "Te-131": 6e-6, // (Vapor)
    "Te-131m": 1e-7, // (Vapor/Particulate)
    "Te-132": 7e-8, // (Vapor)
    "Th-227": 7e-11, // (M)
    "Th-228": 2e-11, // (W/Y)
    "Th-229": 2e-12, // (W)
    "Th-230": 3e-12, // (W)
    "Th-231": 1e-6, // (W/Y)
    "Th-232": 3e-12, // (W)
    "Th-234": 9e-8, // (Y)
    "Ti-44": 7e-9, // (M)
    "Tl-200": 8e-7,
    "Tl-201": 4e-6,
    "Tl-202": 1e-6,
    "Tl-204": 9e-7,
    "Tm-167": 5e-7,
    "Tm-170": 1e-7,
    "Tm-171": 2e-7,

    // U
    "U-230": 4e-11, // (S)
    "U-232": 2e-11, // (S)
    "U-233": 7e-11, // (S)
    "U-234": 7e-11, // (S)
    "U-235": 8e-11, // (S)
    "U-236": 7e-11, // (S)
    "U-237": 3e-7, // (M/S)
    "U-238": 8e-11, // (S)
    "U-239": 9e-6, // (M/S)
    "U-240": 6e-7, // (S)

    // V
    "V-48": 2e-7, // (F/M)
    "V-49": 1e-5, // (M)

    // W
    "W-178": 3e-6,
    "W-181": 1e-5,
    "W-185": 2e-6,
    "W-187": 1e-6,
    "W-188": 6e-7,

    // X
    "Xe-120": 1e-5, // (Immersion)
    "Xe-121": 2e-6, // (Immersion)
    "Xe-122": 8e-5, // (Immersion)
    "Xe-123": 6e-6, // (Immersion)
    "Xe-125": 2e-5, // (Immersion)
    "Xe-127": 1e-5, // (Immersion)
    "Xe-129m": 2e-4, // (Immersion)
    "Xe-131m": 3e-4, // (Immersion)
    "Xe-133": 1e-4, // (Immersion)
    "Xe-133m": 1e-4, // (Immersion)
    "Xe-135": 2e-5, // (Immersion)
    "Xe-135m": 1e-5, // (Immersion)
    "Xe-138": 3e-6, // (Immersion)

    // Y
    "Y-86": 4e-7, // (M/S)
    "Y-87": 8e-7, // (S)
    "Y-88": 1e-7, // (M/S)
    "Y-90": 3e-7, // (M/S)
    "Y-91": 9e-8, // (S)
    "Y-91m": 2e-5, // (M/S)
    "Y-92": 2e-6, // (M/S)
    "Y-93": 9e-7, // (M/S)
    "Yb-169": 2e-7, // (M/S)
    "Yb-175": 8e-7, // (M/S)

    // Z
    "Zn-62": 8e-7, // (S)
    "Zn-63": 5e-6, // (S)
    "Zn-65": 2e-7, // (S)
    "Zn-69": 7e-6, // (S)
    "Zn-69m": 1e-6, // (S)
    "Zr-88": 1e-7, // (F)
    "Zr-89": 6e-7, // (F/M/S)
    "Zr-93": 3e-9, // (F)
    "Zr-95": 9e-8, // (F)
    "Zr-97": 4e-7, // (M/S)

    // Default
    "Other": 2e-13, // (Alpha/SF Default)
    "Other_Noble_Gas_lt_2h": 1e-6 // (Default for unlisted noble gas <2h)
  };
  static double getDac(String name) {
    return dacValues[name] ?? 2e-13; // Default to Other if not found
  }

  static List<String> get nuclideNames => dacValues.keys.toList()..sort();

  static List<String> get extremityNuclides => [
    'Sr/Y-90',
    'Cs-137',
    'Co-60',
    'U-nat',
    'Other'
  ];
}
