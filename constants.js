
import { RespiratoryProtectionFactorEnum, EngineeringProtectionFactorEnum } from './types.js';

export const DPM_PER_MICROCURIE = 2.22e6;
export const HOURS_PER_YEAR_DAC_CONVERSION = 2000; // Standard hours for DAC conversion
export const MREM_PER_DAC_YEAR_CONVERSION = 5000; // mrem exposure from 1 DAC for 2000 hours

export const WORKER_INEFFICIENCY_FACTOR = 1.15;

export const RESPIRATORY_PROTECTION_FACTORS = [
  { name: 'None', value: RespiratoryProtectionFactorEnum.None },
  { name: 'APR (Air-Purifying Respirator)', value: RespiratoryProtectionFactorEnum.APR },
  { name: 'PAPR (Powered Air-Purifying Respirator)', value: RespiratoryProtectionFactorEnum.PAPR },
];

export const ENGINEERING_PROTECTION_FACTORS = [
  { name: 'Type I (Open Bench/Tabletop)', value: EngineeringProtectionFactorEnum.TypeI },
  { name: 'Type II (Fume Hood)', value: EngineeringProtectionFactorEnum.TypeII },
  { name: 'Type III (Glove Box/Hot Cell)', value: EngineeringProtectionFactorEnum.TypeIII },
];

export const INITIAL_RADIONUCLIDES_COUNT = 1;

export const DEFAULT_MPIF_BASE = 1e-6; // 10^-6 (m^-1) from form section A