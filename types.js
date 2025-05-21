
export interface SectionAData {
  r: number;
  c: number;
  d: number;
  o: number; // Occupancy Factor
  s: number;
  u: number;
  calculatedMPIF: number | null;
}

export interface SectionBData {
  location: string;
  numWorkers: number;
  hoursPerWorker: number;
  calculatedPersonHours: number | null;
}

export interface SectionCData {
  directExposureRate: number; // mrem/hr
  calculatedExternalExposure: number | null; // mrem
}

// For Section G nuclides (Internal Dose source term)
export interface RadionuclideAnalysis {
  id: string;
  radionuclideKey: string; 
  name: string; 
  dacValue: number; 
  grossContaminationLevel: number; 

  // Calculated for G
  calculatedAirborneConcentration: number | null; // µCi/cm³

  // Calculated for J-like scenario (with Eng Controls)
  calculatedCA_EngControls: number | null; // CA = AirborneConc / (PFR * PFE)
}

// Data for one scenario of internal dose calculation (either with or without eng controls)
export interface InternalDoseScenarioData {
  // Per-nuclide contributions to this scenario's dose
  radionuclideContributions: Array<{
    radionuclideId: string; // links back to RadionuclideAnalysis.id
    internalExposureNoResp: number | null;
    internalExposureWithResp: number | null;
  }>;
  // Totals for this scenario
  totalInternalExposureWithoutResp: number | null;
  totalInternalExposureWithResp: number | null;
  isRespiratoryProtectionPrescribed: boolean;
  explanation: string;
}

export interface SectionKData {
  radionuclideDacFractions: Array<{
    radionuclideId: string;
    dacFraction: number | null;
  }>;
  totalDacFraction: number | null;
  // Triggers from form
  isAirSamplingRequiredOver03DAC: boolean; // ≥ 0.3 DAC Fraction averaged over 40 hours...
  isAreaPostedARA: boolean; // > 1 DAC Fraction or ≥ 12 DAC-hrs/week...
  comments: string;
}

export interface SectionMData {
  externalExposure: number | null; // from C
  internalExposure: number | null; // Selected from I or J logic based on eng controls used
  effectiveDose: number | null; // Final TED for the task
}

export interface SectionFRadionuclideData {
  id: string;
  radionuclideKey: string;
  name: string; 
  timePerWorkerHours: number; 
  extremitySkinDoseRate: number; 
  calculatedExtremitySkinDose: number | null;
}

export interface SectionFData {
  radionuclides: SectionFRadionuclideData[];
  totalExposurePerIndividual: number | null;
  isDosimetryPrescribed: boolean;
  comments: string;
}

export interface SectionEData {
  directHandling: boolean;
  shieldedGloveboxWork: boolean;
  shieldingLeaks: boolean;
  nonUniformMaterials: boolean;
  protectiveClothingLeadedGarments: boolean;
  rsoDeemedNecessary: boolean;
}

export interface TaskData {
  id: string;
  title: string;
  
  // External Dose Group
  sectionB: SectionBData; // Time Estimation
  sectionC: SectionCData; // External Dose Rate - Direct
  sectionE: SectionEData; // Extremity/Skin Triggers
  sectionF: SectionFData; // Extremity/Skin Dose Estimate

  // Internal Dose Group
  sectionA: SectionAData; // mPIF
  radionuclidesInternal: RadionuclideAnalysis[]; // Section G - Internal dose source term nuclides
  
  // Task-specific protection factors (Section H logic)
  respiratoryProtectionFactorValue: RespiratoryProtectionFactorEnum;
  engineeringProtectionFactorValue: EngineeringProtectionFactorEnum;
  
  engineeringControlsUsed: boolean; // Yes/No toggle for which internal dose path to use in M

  // Internal Dose Scenario Calculations
  internalDoseWithoutEngControls: InternalDoseScenarioData; // Logic of former Sec I
  internalDoseWithEngControls: InternalDoseScenarioData;    // Logic of former Sec J
                                                
  sectionK: SectionKData; // DAC Fraction calculations
  sectionM: SectionMData; // Summary
}

// GlobalFactors is now minimal, PFR/PFE are task-specific
export interface GlobalFactors {
  // Potentially for future global settings, e.g., default occupancy if not overridden
}

export enum RespiratoryProtectionFactorEnum {
  None = 1,
  APR = 50,
  PAPR = 1000,
}

export enum EngineeringProtectionFactorEnum {
  TypeI = 1,        // Open Bench / Tabletop (No effective engineering control for PFE)
  TypeII = 1000,    // Fume Hood
  TypeIII = 100000, // Glove Box, Hot Cell
}