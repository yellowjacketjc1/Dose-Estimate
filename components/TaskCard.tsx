
import React, { useState, useEffect, useCallback } from 'react';
// HACK: Fix: Changed type-only import for enums to regular import
import { 
  RespiratoryProtectionFactorEnum, EngineeringProtectionFactorEnum 
} from '../types.ts';
import type { 
  TaskData, RadionuclideAnalysis, GlobalFactors, SectionAData, SectionBData, SectionCData, SectionEData, 
  SectionFData, SectionFRadionuclideData, InternalDoseScenarioData, SectionKData, SectionMData
} from '../types.ts';
import { RadionuclideRow } from './RadionuclideRow.tsx';
import { SectionFRadionuclideRow } from './SectionFRadionuclideRow.tsx';
import { PlusIcon, TrashIcon, ChevronDownIcon, ChevronUpIcon } from './icons.tsx';
import { 
  DEFAULT_MPIF_BASE, WORKER_INEFFICIENCY_FACTOR, DPM_PER_MICROCURIE, 
  HOURS_PER_YEAR_DAC_CONVERSION, MREM_PER_DAC_YEAR_CONVERSION,
  RESPIRATORY_PROTECTION_FACTORS, ENGINEERING_PROTECTION_FACTORS
} from '../constants.ts';

interface TaskCardProps {
  task: TaskData;
  globalFactors: GlobalFactors; // Minimal, but passed for consistency
  onUpdateTask: (updatedTask: TaskData) => void;
  onRemoveTask: () => void;
}

// --- UI Helper Components (defined within TaskCard for encapsulation) ---
const SectionHeader: React.FC<{ title: string; subtitle?: string; children?: React.ReactNode, isCollapsed: boolean, onToggle: () => void }> = ({ title, subtitle, children, isCollapsed, onToggle }) => (
  <div className="mb-3 border-b border-slate-200 pb-2">
    <button onClick={onToggle} className="w-full flex justify-between items-center text-left py-2 hover:bg-slate-50 rounded">
      <div>
        <h3 className="text-lg font-semibold text-blue-700">{title}</h3>
        {subtitle && <p className="text-sm text-slate-600 -mt-1">{subtitle}</p>}
      </div>
      {isCollapsed ? <ChevronDownIcon className="w-5 h-5 text-blue-700"/> : <ChevronUpIcon className="w-5 h-5 text-blue-700"/>}
    </button>
    {!isCollapsed && <div className="mt-3">{children}</div>}
  </div>
);

const InputField: React.FC<{ 
  label: string; 
  value: string | number; 
  onChange: (value: string) => void; // Always string for input event
  onBlur?: () => void;
  type?: string; 
  placeholder?: string; 
  units?: string; 
  helpText?: string; 
  id: string;
  readOnly?: boolean;
  inputClassName?: string;
}> = ({ label, value, onChange, onBlur, type = "text", placeholder, units, helpText, id, readOnly = false, inputClassName ="" }) => (
  <div className="flex flex-col space-y-1">
    <label htmlFor={id} className="text-sm font-medium text-slate-700">{label} {units && <span className="text-xs text-slate-500">({units})</span>}</label>
    <input
      id={id}
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onBlur={onBlur}
      placeholder={placeholder}
      readOnly={readOnly}
      className={`form-input block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 ${readOnly ? 'bg-slate-100 cursor-not-allowed' : 'bg-white'} ${inputClassName}`}
      aria-readonly={readOnly}
      aria-describedby={helpText ? `${id}-help` : undefined}
    />
    {helpText && <p id={`${id}-help`} className="text-xs text-slate-500">{helpText}</p>}
  </div>
);

const CalculatedDisplayField: React.FC<{ 
  label: string; 
  value: number | string | null; 
  units?: string; 
  precision?: number; 
  helpText?: string 
}> = ({ label, value, units, precision = 4, helpText }) => (
  <div className="flex flex-col space-y-1">
    <span className="text-sm font-medium text-slate-700">{label} {units && <span className="text-xs text-slate-500">({units})</span>}</span>
    <span className="text-sm p-2 min-h-[2.5rem] flex items-center bg-slate-50 rounded-md border border-slate-200">
      {typeof value === 'number' ? value.toExponential(precision) : (value ?? 'N/A')}
    </span>
    {helpText && <p className="text-xs text-slate-500 mt-1">{helpText}</p>}
  </div>
);

const CheckboxField: React.FC<{
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  id: string;
  details?: string;
}> = ({ label, checked, onChange, id, details }) => (
  <div className="relative flex items-start py-1">
    <div className="flex h-5 items-center">
      <input
        id={id}
        aria-describedby={details ? `${id}-description` : undefined}
        name={id}
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
      />
    </div>
    <div className="ml-3 text-sm">
      <label htmlFor={id} className="font-medium text-slate-700">{label}</label>
      {details && <p id={`${id}-description`} className="text-slate-500 text-xs">{details}</p>}
    </div>
  </div>
);

const RadioButtonGroup: React.FC<{
  legend: string;
  options: Array<{label: string; value: string | number; helpText?: string}>;
  selectedValue: string | number;
  onChange: (value: string | number) => void;
  name: string;
}> = ({ legend, options, selectedValue, onChange, name}) => (
    <fieldset className="space-y-2">
        <legend className="text-sm font-medium text-slate-700">{legend}</legend>
        {options.map(option => (
            <label key={String(option.value)} className="flex items-center text-sm">
                <input 
                    type="radio" 
                    name={name} 
                    value={option.value}
                    checked={selectedValue === option.value}
                    onChange={(e) => onChange(option.value === String(parseFloat(String(option.value))) ? parseFloat(String(option.value)) : e.target.value)}
                    className="form-radio h-4 w-4 text-blue-600 border-slate-300 focus:ring-blue-500"
                />
                <span className="ml-2 text-slate-700">{option.label}</span>
                {option.helpText && <span className="ml-1 text-xs text-slate-500">({option.helpText})</span>}
            </label>
        ))}
    </fieldset>
);
// --- END UI Helper Components ---


export const TaskCard: React.FC<TaskCardProps> = ({ task, onUpdateTask, onRemoveTask }) => {
  const [collapsedSections, setCollapsedSections] = useState<Record<string, boolean>>({
    externalDoseGroup: false,
    internalDoseGroup: false,
    sectionK_dacFraction: false,
    sectionM_summary: false,
    // Fine-grained within groups if needed later
    sectionA: true, sectionB: false, sectionC: true, sectionE: true, sectionF: true, 
    sectionG_radionuclides: false, sectionH_protectionFactors: false,
    internalDose_NoEng: false, internalDose_WithEng: false,
  });

  const toggleSection = (sectionName: string) => {
    setCollapsedSections(prev => ({ ...prev, [sectionName]: !prev[sectionName] }));
  };

  const updateTaskField = <K extends keyof TaskData>(field: K, value: TaskData[K]) => {
    onUpdateTask({ ...task, [field]: value });
  };

  // Specific updaters for nested sections
  const updateSectionA = <K extends keyof SectionAData>(field: K, value: SectionAData[K]) => updateTaskField('sectionA', { ...task.sectionA, [field]: value });
  const updateSectionB = <K extends keyof SectionBData>(field: K, value: SectionBData[K]) => updateTaskField('sectionB', { ...task.sectionB, [field]: value });
  const updateSectionC = <K extends keyof SectionCData>(field: K, value: SectionCData[K]) => updateTaskField('sectionC', { ...task.sectionC, [field]: value });
  const updateSectionE = <K extends keyof SectionEData>(field: K, value: SectionEData[K]) => updateTaskField('sectionE', { ...task.sectionE, [field]: value });
  const updateSectionF = <K extends keyof SectionFData>(field: K, value: SectionFData[K]) => updateTaskField('sectionF', { ...task.sectionF, [field]: value });
  const updateSectionK = <K extends keyof SectionKData>(field: K, value: SectionKData[K]) => updateTaskField('sectionK', { ...task.sectionK, [field]: value });

  const updateInternalDoseScenario = (scenarioType: 'internalDoseWithoutEngControls' | 'internalDoseWithEngControls', field: keyof InternalDoseScenarioData, value: any) => {
    updateTaskField(scenarioType, { ...task[scenarioType], [field]: value });
  };


  const handleNumericChange = (setter: (valStr: string) => void, valueStr: string, parser: (val:string) => number = parseFloat) => {
      setter(valueStr); // Let string state update freely
      // Actual parsing and model update happens onBlur or via recalculate
  };
  
  const handleNumericBlur = (
    currentStrValue: string,
    modelUpdater: (numValue: number) => void,
    defaultValue: number = 0
  ) => {
    const num = parseFloat(currentStrValue);
    if (!isNaN(num)) {
      modelUpdater(num);
    } else {
      modelUpdater(defaultValue); // Or revert to previous valid model value if preferred
    }
  };


  // Radionuclide Management for Section G (Internal)
  const addInternalRadionuclide = () => {
    const newRad: RadionuclideAnalysis = {
      id: `nuc-int-${task.id}-${Date.now()}`, radionuclideKey: 'custom', name: '', dacValue: 0, grossContaminationLevel: 0,
      calculatedAirborneConcentration: null, calculatedCA_EngControls: null,
    };
    const updatedRadionuclides = [...task.radionuclidesInternal, newRad];
    // Also update corresponding entries in scenario contributions and sectionK
    const newNoEngContributions = [...task.internalDoseWithoutEngControls.radionuclideContributions, { radionuclideId: newRad.id, internalExposureNoResp: null, internalExposureWithResp: null }];
    const newWithEngContributions = [...task.internalDoseWithEngControls.radionuclideContributions, { radionuclideId: newRad.id, internalExposureNoResp: null, internalExposureWithResp: null }];
    const newKContributions = [...task.sectionK.radionuclideDacFractions, { radionuclideId: newRad.id, dacFraction: null }];

    onUpdateTask({ 
      ...task, 
      radionuclidesInternal: updatedRadionuclides,
      internalDoseWithoutEngControls: { ...task.internalDoseWithoutEngControls, radionuclideContributions: newNoEngContributions },
      internalDoseWithEngControls: { ...task.internalDoseWithEngControls, radionuclideContributions: newWithEngContributions },
      sectionK: { ...task.sectionK, radionuclideDacFractions: newKContributions }
    });
  };

  const updateInternalRadionuclide = (index: number, updatedNuc: RadionuclideAnalysis) => {
    const newRadionuclides = [...task.radionuclidesInternal];
    newRadionuclides[index] = updatedNuc;
    updateTaskField('radionuclidesInternal', newRadionuclides);
  };

  const removeInternalRadionuclide = (index: number, nuclideId: string) => {
    if (task.radionuclidesInternal.length > 1) {
      const newRadionuclides = task.radionuclidesInternal.filter((_, i) => i !== index);
      // Also remove from dependent structures
      const newNoEngContributions = task.internalDoseWithoutEngControls.radionuclideContributions.filter(c => c.radionuclideId !== nuclideId);
      const newWithEngContributions = task.internalDoseWithEngControls.radionuclideContributions.filter(c => c.radionuclideId !== nuclideId);
      const newKContributions = task.sectionK.radionuclideDacFractions.filter(c => c.radionuclideId !== nuclideId);

      onUpdateTask({ 
        ...task, 
        radionuclidesInternal: newRadionuclides,
        internalDoseWithoutEngControls: { ...task.internalDoseWithoutEngControls, radionuclideContributions: newNoEngContributions },
        internalDoseWithEngControls: { ...task.internalDoseWithEngControls, radionuclideContributions: newWithEngContributions },
        sectionK: { ...task.sectionK, radionuclideDacFractions: newKContributions }
      });
    }
  };

  // Radionuclide Management for Section F (Extremity/Skin)
  const addSectionFRadionuclide = () => {
    const newRad: SectionFRadionuclideData = {
      id: `nuc-secF-${task.id}-${Date.now()}`, radionuclideKey: 'custom', name: '', 
      timePerWorkerHours: 0, extremitySkinDoseRate: 0, calculatedExtremitySkinDose: null,
    };
    updateSectionF('radionuclides', [...task.sectionF.radionuclides, newRad]);
  };

  const updateSectionFRadionuclide = (index: number, updatedNuc: SectionFRadionuclideData) => {
    const newRadionuclides = [...task.sectionF.radionuclides];
    newRadionuclides[index] = updatedNuc;
    updateSectionF('radionuclides', newRadionuclides);
  };

  const removeSectionFRadionuclide = (index: number) => {
    if (task.sectionF.radionuclides.length > 1) {
      updateSectionF('radionuclides', task.sectionF.radionuclides.filter((_, i) => i !== index));
    }
  };

  // --- Main Calculation Logic ---
  const recalculateTask = useCallback(() => {
    const originalTaskJson = JSON.stringify(task);
    
    let updatedTask = { ...task };

    // A. mPIF
    updatedTask.sectionA.calculatedMPIF = DEFAULT_MPIF_BASE * updatedTask.sectionA.r * updatedTask.sectionA.c * updatedTask.sectionA.d * updatedTask.sectionA.o * updatedTask.sectionA.s * updatedTask.sectionA.u;

    // B. Person-hours
    updatedTask.sectionB.calculatedPersonHours = updatedTask.sectionB.numWorkers * updatedTask.sectionB.hoursPerWorker;
    const personHours = updatedTask.sectionB.calculatedPersonHours ?? 0;

    // C. External Exposure
    updatedTask.sectionC.calculatedExternalExposure = updatedTask.sectionC.directExposureRate * personHours;

    // F. Extremity/Skin Dose
    let totalSecFDose = 0;
    updatedTask.sectionF.radionuclides = updatedTask.sectionF.radionuclides.map(nucF => {
      const dose = nucF.timePerWorkerHours * nucF.extremitySkinDoseRate;
      totalSecFDose += dose;
      return { ...nucF, calculatedExtremitySkinDose: dose };
    });
    updatedTask.sectionF.totalExposurePerIndividual = totalSecFDose;

    // G. Airborne Concentration (for each internal radionuclide)
    updatedTask.radionuclidesInternal = updatedTask.radionuclidesInternal.map(nuc => {
      let airborneConc: number | null = null;
      if (updatedTask.sectionA.calculatedMPIF !== null && nuc.grossContaminationLevel > 0 && nuc.dacValue > 0) {
        airborneConc = (nuc.grossContaminationLevel / 100) * updatedTask.sectionA.calculatedMPIF * (1 / 100) * (1 / DPM_PER_MICROCURIE);
      }
      return { ...nuc, calculatedAirborneConcentration: airborneConc };
    });

    const pfr = updatedTask.respiratoryProtectionFactorValue;
    const pfe = updatedTask.engineeringProtectionFactorValue;
    const doseConversionFactor = (personHours / HOURS_PER_YEAR_DAC_CONVERSION) * MREM_PER_DAC_YEAR_CONVERSION;

    // Internal Dose Scenario: WITHOUT Engineering Controls (PFE_effective = 1 for dose)
    let scenarioNoEng = { ...updatedTask.internalDoseWithoutEngControls, totalInternalExposureWithoutResp: 0, totalInternalExposureWithResp: 0 };
    scenarioNoEng.radionuclideContributions = updatedTask.radionuclidesInternal.map(nuc => {
      let noResp: number | null = null;
      let withResp: number | null = null;
      if (nuc.calculatedAirborneConcentration !== null && nuc.dacValue > 0) {
        noResp = (nuc.calculatedAirborneConcentration / nuc.dacValue) * doseConversionFactor;
        withResp = pfr > 0 ? noResp / pfr : noResp; // pfr is always >= 1
        scenarioNoEng.totalInternalExposureWithoutResp! += noResp;
        scenarioNoEng.totalInternalExposureWithResp! += withResp;
      }
      return { radionuclideId: nuc.id, internalExposureNoResp: noResp, internalExposureWithResp: withResp };
    });
    updatedTask.internalDoseWithoutEngControls = scenarioNoEng;

    // Internal Dose Scenario: WITH Engineering Controls
    let scenarioWithEng = { ...updatedTask.internalDoseWithEngControls, totalInternalExposureWithoutResp: 0, totalInternalExposureWithResp: 0 };
    updatedTask.radionuclidesInternal = updatedTask.radionuclidesInternal.map(nuc => { 
        let ca_EngControls: number | null = null;
        if (nuc.calculatedAirborneConcentration !== null && pfr > 0 && pfe > 0) { // pfr and pfe are always >=1
            ca_EngControls = nuc.calculatedAirborneConcentration / (pfr * pfe);
        }
        return {...nuc, calculatedCA_EngControls: ca_EngControls};
    });

    scenarioWithEng.radionuclideContributions = updatedTask.radionuclidesInternal.map(nuc => {
        let noRespEng: number | null = null;
        let withRespEng: number | null = null; 

        if (nuc.calculatedAirborneConcentration !== null && nuc.dacValue > 0 && pfe > 0) { // pfe is always >=1
            const effectiveAirborneConcWithPFE = nuc.calculatedAirborneConcentration / pfe;
            noRespEng = (effectiveAirborneConcWithPFE / nuc.dacValue) * doseConversionFactor;
            scenarioWithEng.totalInternalExposureWithoutResp! += noRespEng;

            if (nuc.calculatedCA_EngControls !== null) { 
                 withRespEng = (nuc.calculatedCA_EngControls / nuc.dacValue) * doseConversionFactor;
            } else if (noRespEng !== null && pfr > 0) { // pfr is always >=1
                 withRespEng = noRespEng / pfr;
            } else {
                withRespEng = noRespEng;
            }
            scenarioWithEng.totalInternalExposureWithResp! += withRespEng ?? 0;

        }
        return { radionuclideId: nuc.id, internalExposureNoResp: noRespEng, internalExposureWithResp: withRespEng };
    });
    updatedTask.internalDoseWithEngControls = scenarioWithEng;


    // K. DAC Fraction
    let totalDacFraction = 0;
    const pfeForDacFraction = updatedTask.engineeringControlsUsed ? pfe : EngineeringProtectionFactorEnum.TypeI; 
    updatedTask.sectionK.radionuclideDacFractions = updatedTask.radionuclidesInternal.map(nuc => {
      let dacFrac: number | null = null;
      if (nuc.calculatedAirborneConcentration !== null && nuc.dacValue > 0 && pfeForDacFraction > 0) { // pfeForDacFraction always >=1
        dacFrac = (nuc.calculatedAirborneConcentration / pfeForDacFraction) / nuc.dacValue;
        totalDacFraction += dacFrac;
      }
      return { radionuclideId: nuc.id, dacFraction: dacFrac };
    });
    updatedTask.sectionK.totalDacFraction = totalDacFraction;
    updatedTask.sectionK.isAirSamplingRequiredOver03DAC = totalDacFraction >= 0.3;
    updatedTask.sectionK.isAreaPostedARA = totalDacFraction >= 1.0; 

    // M. Effective Exposure Summary
    updatedTask.sectionM.externalExposure = updatedTask.sectionC.calculatedExternalExposure;
    let internalDoseForM: number | null = null;
    let isRespPrescribedForM = false;

    if (updatedTask.engineeringControlsUsed) {
      internalDoseForM = scenarioWithEng.isRespiratoryProtectionPrescribed ? scenarioWithEng.totalInternalExposureWithResp : scenarioWithEng.totalInternalExposureWithoutResp;
      isRespPrescribedForM = scenarioWithEng.isRespiratoryProtectionPrescribed;
    } else {
      internalDoseForM = scenarioNoEng.isRespiratoryProtectionPrescribed ? scenarioNoEng.totalInternalExposureWithResp : scenarioNoEng.totalInternalExposureWithoutResp;
      isRespPrescribedForM = scenarioNoEng.isRespiratoryProtectionPrescribed;
    }
    updatedTask.sectionM.internalExposure = internalDoseForM;

    if (updatedTask.sectionM.externalExposure !== null && updatedTask.sectionM.internalExposure !== null) {
      const sumDose = updatedTask.sectionM.externalExposure + updatedTask.sectionM.internalExposure;
      updatedTask.sectionM.effectiveDose = isRespPrescribedForM ? sumDose * WORKER_INEFFICIENCY_FACTOR : sumDose;
    } else {
      updatedTask.sectionM.effectiveDose = null;
    }

    const finalUpdatedTaskJson = JSON.stringify(updatedTask);
    if (originalTaskJson !== finalUpdatedTaskJson) {
      onUpdateTask(updatedTask);
    }
  }, [task, onUpdateTask]); 

  useEffect(() => {
    recalculateTask();
  }, [recalculateTask]);


  const selectedInternalDoseScenario = task.engineeringControlsUsed ? task.internalDoseWithEngControls : task.internalDoseWithoutEngControls;
  const selectedInternalDoseScenarioKey = task.engineeringControlsUsed ? 'internalDoseWithEngControls' : 'internalDoseWithoutEngControls';

  return (
    <div className="bg-white p-6 rounded-lg shadow-lg border border-slate-200 relative">
      <div className="flex justify-between items-start mb-4">
         <InputField 
          id={`taskTitle-${task.id}`}
          label=""
          value={task.title} 
          onChange={(val) => updateTaskField('title', val)}
          placeholder="Task Title"
          inputClassName="text-xl font-semibold !border-0 !shadow-none focus:!ring-0"
        />
        <button onClick={onRemoveTask} className="ml-4 p-2 text-red-500 hover:text-red-700" aria-label="Remove task">
          <TrashIcon className="w-6 h-6" />
        </button>
      </div>
      
      {/* --- EXTERNAL DOSE GROUP --- */}
      <SectionHeader title="EXTERNAL DOSE ESTIMATES" isCollapsed={collapsedSections.externalDoseGroup} onToggle={() => toggleSection('externalDoseGroup')}>
        {/* B. Time Estimation */}
        <SectionHeader title="B. Time Estimation" isCollapsed={collapsedSections.sectionB} onToggle={() => toggleSection('sectionB')}>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <InputField id={`secB-location-${task.id}`} label="Location" value={task.sectionB.location} onChange={val => updateSectionB('location', val)} placeholder="e.g., Bldg. 203 - ECR3"/>
            <InputField id={`secB-numWorkers-${task.id}`} label="No. of Workers" type="number" value={task.sectionB.numWorkers} onChange={val => handleNumericChange(str => updateSectionB('numWorkers', parseFloat(str) || 0), val)} onBlur={() => handleNumericBlur(String(task.sectionB.numWorkers), num => updateSectionB('numWorkers', num))} />
            <InputField id={`secB-hrsPerWorker-${task.id}`} label="Hours/Worker" type="number" value={task.sectionB.hoursPerWorker} onChange={val => handleNumericChange(str => updateSectionB('hoursPerWorker', parseFloat(str) || 0), val)}  onBlur={() => handleNumericBlur(String(task.sectionB.hoursPerWorker), num => updateSectionB('hoursPerWorker', num))} />
            <CalculatedDisplayField label="Time" value={task.sectionB.calculatedPersonHours} units="Person-hours" helpText="No. Workers × Hrs/Worker"/>
          </div>
        </SectionHeader>

        {/* C. External Dose Rate - Direct Reading */}
        <SectionHeader title="C. External Dose Rate - Direct Reading" isCollapsed={collapsedSections.sectionC} onToggle={() => toggleSection('sectionC')}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <InputField id={`secC-directExposureRate-${task.id}`} label="Direct Exposure Rate" type="number" value={task.sectionC.directExposureRate} onChange={val => handleNumericChange(str => updateSectionC('directExposureRate', parseFloat(str) || 0), val)} onBlur={() => handleNumericBlur(String(task.sectionC.directExposureRate), num => updateSectionC('directExposureRate', num))} units="mrem/hr"/>
            <CalculatedDisplayField label="External Exposure" value={task.sectionC.calculatedExternalExposure} units="mrem" helpText="Exposure Rate × Person-hours"/>
          </div>
        </SectionHeader>
        
        {/* E. Extremity and Skin Dose Evaluation Triggers */}
        <SectionHeader title="E. Extremity and Skin Dose Evaluation Triggers" subtitle="If any checked, complete Section F." isCollapsed={collapsedSections.sectionE} onToggle={() => toggleSection('sectionE')}>
            <div className="space-y-3">
                <p className="text-sm text-slate-600 mb-2">Working in a non-uniform radiation field...</p>
                <CheckboxField id={`secE-directHandling-${task.id}`} label="Direct handling..." checked={task.sectionE.directHandling} onChange={(c) => updateSectionE('directHandling', c)} />
                <CheckboxField id={`secE-shieldedGlovebox-${task.id}`} label="Shielded glovebox work..." checked={task.sectionE.shieldedGloveboxWork} onChange={(c) => updateSectionE('shieldedGloveboxWork', c)} />
                <CheckboxField id={`secE-shieldingLeaks-${task.id}`} label="Shielding leaks..." checked={task.sectionE.shieldingLeaks} onChange={(c) => updateSectionE('shieldingLeaks', c)} />
                <CheckboxField id={`secE-nonUniformMats-${task.id}`} label="Non-uniform materials..." checked={task.sectionE.nonUniformMaterials} onChange={(c) => updateSectionE('nonUniformMaterials', c)} />
                <CheckboxField id={`secE-protectiveClothing-${task.id}`} label="Protective clothing/leaded garments..." checked={task.sectionE.protectiveClothingLeadedGarments} onChange={(c) => updateSectionE('protectiveClothingLeadedGarments', c)} />
                <CheckboxField id={`secE-rsoDeemed-${task.id}`} label="RSO deemed necessary..." checked={task.sectionE.rsoDeemedNecessary} onChange={(c) => updateSectionE('rsoDeemedNecessary', c)} />
            </div>
        </SectionHeader>

        {/* F. Extremity and Skin Dose Estimate */}
        <SectionHeader title="F. Extremity and Skin Dose Estimate" subtitle="Complete if required by Section E." isCollapsed={collapsedSections.sectionF} onToggle={() => toggleSection('sectionF')}>
          <div className="space-y-4">
            {task.sectionF.radionuclides.map((nucF, index) => (
              <SectionFRadionuclideRow key={nucF.id} radionuclide={nucF} onUpdate={(upNuc) => updateSectionFRadionuclide(index, upNuc)} onRemove={() => removeSectionFRadionuclide(index)} isOnlyRadionuclide={task.sectionF.radionuclides.length === 1} parentId={`task-${task.id}-secF`}/>
            ))}
          </div>
          <button onClick={addSectionFRadionuclide} className="mt-4 flex items-center text-sm text-blue-600 hover:text-blue-800"><PlusIcon className="w-4 h-4 mr-1" /> Add Nuclide for Sec F</button>
          <CalculatedDisplayField label="Total Extremity/Skin Exp." value={task.sectionF.totalExposurePerIndividual} units="mrem" />
          <RadioButtonGroup name={`secF-dosimetry-${task.id}`} legend="Will extremity dosimetry be prescribed? (Required if > 1000 mrem)" options={[{label: 'Yes', value: 'true'}, {label: 'No', value: 'false'}]} selectedValue={String(task.sectionF.isDosimetryPrescribed)} onChange={val => updateSectionF('isDosimetryPrescribed', val === 'true')} />
          <InputField id={`secF-comments-${task.id}`} label="Comments (Section F)" value={task.sectionF.comments} onChange={val => updateSectionF('comments', val)} />
        </SectionHeader>
      </SectionHeader>


      {/* --- INTERNAL DOSE GROUP --- */}
      <SectionHeader title="INTERNAL DOSE ESTIMATES" isCollapsed={collapsedSections.internalDoseGroup} onToggle={() => toggleSection('internalDoseGroup')}>
        {/* A. mPIF Calculation */}
        <SectionHeader title="A. Resuspension or Modified PIF (mPIF) Calculation" isCollapsed={collapsedSections.sectionA} onToggle={() => toggleSection('sectionA')}>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {['r', 'c', 'd', 'o', 's', 'u'].map(f => (
              <InputField key={f} id={`secA-${f}-${task.id}`} label={f.toUpperCase()} type="number" value={task.sectionA[f as keyof SectionAData]} onChange={val => handleNumericChange(str => updateSectionA(f as keyof SectionAData, parseFloat(str) || 0), val)} onBlur={() => handleNumericBlur(String(task.sectionA[f as keyof SectionAData]), num => updateSectionA(f as keyof SectionAData, num))} />
            ))}
            <CalculatedDisplayField label="mPIF" value={task.sectionA.calculatedMPIF} units="m⁻¹" helpText="10⁻⁶ × R×C×D×O×S×U"/>
          </div>
        </SectionHeader>

        {/* G. Radionuclide Details & Airborne Concentration */}
        <SectionHeader title="G. Radionuclide Details & Airborne Concentration" isCollapsed={collapsedSections.sectionG_radionuclides} onToggle={() => toggleSection('sectionG_radionuclides')}>
          <div className="space-y-4">
            {task.radionuclidesInternal.map((nuc, index) => (
              <RadionuclideRow key={nuc.id} radionuclide={nuc} taskData={task} onUpdate={(upNuc) => updateInternalRadionuclide(index, upNuc)} onRemove={() => removeInternalRadionuclide(index, nuc.id)} isOnlyRadionuclide={task.radionuclidesInternal.length === 1} />
            ))}
          </div>
          <button onClick={addInternalRadionuclide} className="mt-4 flex items-center text-sm text-blue-600 hover:text-blue-800"><PlusIcon className="w-4 h-4 mr-1" /> Add Internal Nuclide</button>
        </SectionHeader>

        {/* H. Airborne Respiratory & Engineering Protection Factors */}
        <SectionHeader title="H. Task-Specific Protection Factors" isCollapsed={collapsedSections.sectionH_protectionFactors} onToggle={() => toggleSection('sectionH_protectionFactors')}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <RadioButtonGroup name={`pfr-${task.id}`} legend="Respiratory Protection (PFR)" options={RESPIRATORY_PROTECTION_FACTORS.map(f => ({label: f.name, value: f.value}))} selectedValue={task.respiratoryProtectionFactorValue} onChange={val => updateTaskField('respiratoryProtectionFactorValue', Number(val))} />
            <RadioButtonGroup name={`pfe-${task.id}`} legend="Engineering Controls (PFE)" options={ENGINEERING_PROTECTION_FACTORS.map(f => ({label: f.name, value: f.value}))} selectedValue={task.engineeringProtectionFactorValue} onChange={val => updateTaskField('engineeringProtectionFactorValue', Number(val))} />
          </div>
        </SectionHeader>
        
        {/* Toggle for Engineering Controls Used */}
        <div className="my-4 p-3 bg-slate-50 rounded-md">
           <RadioButtonGroup name={`engControlsUsed-${task.id}`} legend="Will Engineering Controls (selected in H) be used for this task?" options={[{label: 'Yes', value: 'true'}, {label: 'No', value: 'false'}]} selectedValue={String(task.engineeringControlsUsed)} onChange={val => updateTaskField('engineeringControlsUsed', val === 'true')} />
        </div>

        {/* Conditional Internal Dose Sections */}
        {!task.engineeringControlsUsed && (
          <SectionHeader title="I. Internal Dose (Without Engineering Controls)" isCollapsed={collapsedSections.internalDose_NoEng} onToggle={() => toggleSection('internalDose_NoEng')}>
            <div className="space-y-3">
              {task.internalDoseWithoutEngControls.radionuclideContributions.map(contrib => {
                const nuc = task.radionuclidesInternal.find(n => n.id === contrib.radionuclideId);
                return (
                  <div key={contrib.radionuclideId} className="p-2 border-b">
                    <p className="font-medium text-sm">{nuc?.name || 'Unknown Nuclide'}</p>
                    <CalculatedDisplayField label="Int. Exp (No Resp)" value={contrib.internalExposureNoResp} units="mrem"/>
                    <CalculatedDisplayField label="Int. Exp (With Resp)" value={contrib.internalExposureWithResp} units="mrem"/>
                  </div>
                );
              })}
              <CalculatedDisplayField label="Total Int. Exp (No Resp)" value={task.internalDoseWithoutEngControls.totalInternalExposureWithoutResp} units="mrem"/>
              <CalculatedDisplayField label="Total Int. Exp (With Resp)" value={task.internalDoseWithoutEngControls.totalInternalExposureWithResp} units="mrem"/>
              <RadioButtonGroup name={`respPrescribedNoEng-${task.id}`} legend="Respiratory protection prescribed (for No Eng. Controls scenario)?" options={[{label: 'Yes', value: 'true'}, {label: 'No', value: 'false'}]} selectedValue={String(task.internalDoseWithoutEngControls.isRespiratoryProtectionPrescribed)} onChange={val => updateInternalDoseScenario('internalDoseWithoutEngControls', 'isRespiratoryProtectionPrescribed', val === 'true')} />
              <InputField id={`explNoEng-${task.id}`} label="Explanation" value={task.internalDoseWithoutEngControls.explanation} onChange={val => updateInternalDoseScenario('internalDoseWithoutEngControls', 'explanation', val)} />
            </div>
          </SectionHeader>
        )}

        {task.engineeringControlsUsed && (
          <SectionHeader title="J. Internal Dose (With Engineering Controls)" isCollapsed={collapsedSections.internalDose_WithEng} onToggle={() => toggleSection('internalDose_WithEng')}>
             <div className="space-y-3">
              {task.internalDoseWithEngControls.radionuclideContributions.map(contrib => {
                const nuc = task.radionuclidesInternal.find(n => n.id === contrib.radionuclideId);
                return (
                  <div key={contrib.radionuclideId} className="p-2 border-b">
                    <p className="font-medium text-sm">{nuc?.name || 'Unknown Nuclide'}</p>
                    <CalculatedDisplayField label="CA (Air Conc. after PFR & PFE)" value={nuc?.calculatedCA_EngControls} units="µCi/cm³" helpText="AirborneConc / (PFR×PFE)"/>
                    <CalculatedDisplayField label="Int. Exp (No Resp, With Eng Ctrl)" value={contrib.internalExposureNoResp} units="mrem" helpText="Uses PFE"/>
                    <CalculatedDisplayField label="Int. Exp (With Resp & Eng Ctrl)" value={contrib.internalExposureWithResp} units="mrem" helpText="Uses PFR & PFE (derived from CA)"/>
                  </div>
                );
              })}
              <CalculatedDisplayField label="Total Int. Exp (No Resp, With Eng Ctrl)" value={task.internalDoseWithEngControls.totalInternalExposureWithoutResp} units="mrem"/>
              <CalculatedDisplayField label="Total Int. Exp (With Resp & Eng Ctrl)" value={task.internalDoseWithEngControls.totalInternalExposureWithResp} units="mrem"/>
              <RadioButtonGroup name={`respPrescribedWithEng-${task.id}`} legend="Respiratory protection prescribed (for With Eng. Controls scenario)?" options={[{label: 'Yes', value: 'true'}, {label: 'No', value: 'false'}]} selectedValue={String(task.internalDoseWithEngControls.isRespiratoryProtectionPrescribed)} onChange={val => updateInternalDoseScenario('internalDoseWithEngControls', 'isRespiratoryProtectionPrescribed', val === 'true')} />
              <InputField id={`explWithEng-${task.id}`} label="Explanation" value={task.internalDoseWithEngControls.explanation} onChange={val => updateInternalDoseScenario('internalDoseWithEngControls', 'explanation', val)} />
            </div>
          </SectionHeader>
        )}
      </SectionHeader> {/* End Internal Dose Group */}
      
      {/* K. DAC Fraction */}
      <SectionHeader title="K. DAC Fraction" isCollapsed={collapsedSections.sectionK_dacFraction} onToggle={() => toggleSection('sectionK_dacFraction')}>
         <div className="space-y-3">
            {task.sectionK.radionuclideDacFractions.map(frac => {
                const nuc = task.radionuclidesInternal.find(n => n.id === frac.radionuclideId);
                return (
                    <div key={frac.radionuclideId} className="p-2 border-b">
                        <p className="font-medium text-sm">{nuc?.name || 'Unknown Nuclide'}</p>
                        <CalculatedDisplayField label="DAC Fraction" value={frac.dacFraction} precision={3}/>
                    </div>
                );
            })}
            <CalculatedDisplayField label="Total DAC Fraction" value={task.sectionK.totalDacFraction} precision={3}/>
            <CheckboxField id={`k-airsamp03-${task.id}`} label="Workplace air sampling required (≥0.3 DAC frac avg over 40 hrs)" checked={task.sectionK.isAirSamplingRequiredOver03DAC} onChange={c => updateSectionK('isAirSamplingRequiredOver03DAC', c)} />
            <CheckboxField id={`k-ara-${task.id}`} label="Area posted as ARA (>1 DAC frac or ≥12 DAC-hrs/wk)" checked={task.sectionK.isAreaPostedARA} onChange={c => updateSectionK('isAreaPostedARA', c)} />
            <InputField id={`k-comments-${task.id}`} label="Comments (Section K)" value={task.sectionK.comments} onChange={val => updateSectionK('comments', val)} />
         </div>
      </SectionHeader>

      {/* M. Effective Exposure Summary */}
      <SectionHeader title="M. Task Effective Exposure Summary" isCollapsed={collapsedSections.sectionM_summary} onToggle={() => toggleSection('sectionM_summary')}>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <CalculatedDisplayField label="External Exposure" value={task.sectionM.externalExposure} units="mrem" helpText="From Sec C"/>
            <CalculatedDisplayField label="Internal Exposure" value={task.sectionM.internalExposure} units="mrem" helpText={`From ${task.engineeringControlsUsed ? 'J (With Eng. Controls)' : 'I (No Eng. Controls)'} scenario`}/>
            <CalculatedDisplayField label="Total Effective Dose (Task)" value={task.sectionM.effectiveDose} units="mrem" helpText={`(Ext + Int) ${ (task.engineeringControlsUsed ? task.internalDoseWithEngControls.isRespiratoryProtectionPrescribed : task.internalDoseWithoutEngControls.isRespiratoryProtectionPrescribed) ? '× WIF (1.15)' : ''}`}/>
        </div>
      </SectionHeader>

    </div> // End TaskCard main div
  );
};
