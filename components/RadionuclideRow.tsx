
import React, { useState, useEffect, useCallback } from 'react';
import type { RadionuclideAnalysis, TaskData } from '../types.ts'; // GlobalFactors removed
import { DPM_PER_MICROCURIE } from '../constants.ts';
import { RADIONUCLIDE_DAC_LIST } from '../radionuclideData.ts';
import { TrashIcon } from './icons.tsx';

interface RadionuclideRowProps {
  radionuclide: RadionuclideAnalysis;
  taskData: TaskData; // Keep taskData for sectionA.calculatedMPIF
  onUpdate: (updatedRadionuclide: RadionuclideAnalysis) => void;
  onRemove: () => void;
  isOnlyRadionuclide: boolean;
}

// InputField and CalculatedDisplayField can be shared or defined locally.
// For brevity, assuming they are available (as they were in the previous TaskCard structure).
// If running standalone, these would need to be imported or defined.
const InputField: React.FC<{ 
  label: string; 
  value: string | number;
  onChange: (value: string) => void; 
  onBlur?: () => void;
  type?: string; 
  placeholder?: string; 
  units?: string; 
  helpText?: string; 
  id: string;
  readOnly?: boolean;
}> = ({ label, value, onChange, onBlur, type = "text", placeholder, units, helpText, id, readOnly = false }) => (
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
      className={`form-input block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 ${readOnly ? 'bg-slate-100 cursor-not-allowed' : 'bg-white'}`}
      aria-readonly={readOnly}
    />
    {helpText && <p className="text-xs text-slate-500">{helpText}</p>}
  </div>
);

const CalculatedDisplayField: React.FC<{ label: string; value: number | string | null; units?: string; precision?: number }> = 
  ({ label, value, units, precision = 4 }) => (
  <div className="flex flex-col space-y-1">
    <span className="text-sm font-medium text-slate-700">{label} {units && <span className="text-xs text-slate-500">({units})</span>}</span>
    <span className="text-sm p-2 min-h-[2.5rem] flex items-center bg-slate-50 rounded-md border border-slate-200">
      {typeof value === 'number' ? value.toExponential(precision) : (value ?? 'N/A')}
    </span>
  </div>
);

export const RadionuclideRow: React.FC<RadionuclideRowProps> = ({ radionuclide, taskData, onUpdate, onRemove, isOnlyRadionuclide }) => {
  const { sectionA } = taskData;

  const [editingDacValue, setEditingDacValue] = useState<string>(String(radionuclide.dacValue ?? ''));
  const [editingGrossContaminationLevel, setEditingGrossContaminationLevel] = useState<string>(String(radionuclide.grossContaminationLevel ?? ''));

  useEffect(() => {
    setEditingDacValue(String(radionuclide.dacValue ?? ''));
  }, [radionuclide.dacValue]);

  useEffect(() => {
    setEditingGrossContaminationLevel(String(radionuclide.grossContaminationLevel ?? ''));
  }, [radionuclide.grossContaminationLevel]);


  const calculateAirborneConcentration = useCallback(() => {
    let newAirborneConcentration: number | null = null;
    if (sectionA.calculatedMPIF !== null && radionuclide.grossContaminationLevel > 0) {
      newAirborneConcentration = (radionuclide.grossContaminationLevel / 100) * sectionA.calculatedMPIF * (1 / 100) * (1 / DPM_PER_MICROCURIE);
    }

    if (radionuclide.calculatedAirborneConcentration !== newAirborneConcentration) {
      onUpdate({
        ...radionuclide,
        calculatedAirborneConcentration: newAirborneConcentration,
        // Other calculations (internal dose, DAC fraction) are now handled in TaskCard
      });
    }
  }, [
    radionuclide, // Full radionuclide object because it's spread and its properties are read
    sectionA.calculatedMPIF,
    onUpdate, // onUpdate function prop
    // DPM_PER_MICROCURIE is a constant from import, not a prop or state, so not needed in deps
  ]);
  
   useEffect(() => {
    calculateAirborneConcentration();
  }, [calculateAirborneConcentration]);


  const handleFieldUpdate = <K extends keyof RadionuclideAnalysis>(field: K, value: RadionuclideAnalysis[K]) => {
    onUpdate({ ...radionuclide, [field]: value });
  };
  
  const handleNumericBlur = (
    editingValue: string,
    setter: (val: string) => void,
    modelField: keyof RadionuclideAnalysis,
    currentModelValue: number | null
  ) => {
    const numValue = parseFloat(editingValue);
    if (!isNaN(numValue)) {
      if (numValue !== currentModelValue) {
        handleFieldUpdate(modelField, numValue as any);
      }
    } else if (editingValue === "") {
      if (0 !== currentModelValue) {
         handleFieldUpdate(modelField, 0 as any);
      }
      setter("0"); 
    } else {
      setter(String(currentModelValue ?? ''));
    }
  };

  const handleRadionuclideKeyChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedKey = event.target.value;
    const selectedEntry = RADIONUCLIDE_DAC_LIST.find(entry => entry.key === selectedKey);

    if (selectedEntry) {
      const isCustom = selectedEntry.key === 'custom';
      let newName = radionuclide.name;
      let newDacValue = radionuclide.dacValue;

      if (!isCustom && selectedEntry.dac !== undefined) {
        newName = selectedEntry.displayName; 
        newDacValue = selectedEntry.dac;
      }
      
      setEditingDacValue(String(newDacValue ?? ''));
  
      onUpdate({
        ...radionuclide,
        radionuclideKey: selectedKey,
        name: newName,
        dacValue: newDacValue,
      });
    }
  };
  
  const isCustomSelected = radionuclide.radionuclideKey === 'custom';

  return (
    <div className="p-4 border border-slate-300 rounded-lg bg-white shadow space-y-4 relative">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div>
          <label htmlFor={`nuclideKey-int-${radionuclide.id}`} className="text-sm font-medium text-slate-700">Select Radionuclide</label>
          <select
            id={`nuclideKey-int-${radionuclide.id}`}
            value={radionuclide.radionuclideKey}
            onChange={handleRadionuclideKeyChange}
            className="mt-1 form-select block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 bg-white"
          >
            {RADIONUCLIDE_DAC_LIST.map(entry => (
              <option key={entry.key} value={entry.key}>
                {entry.displayName} {entry.dac ? `(${entry.dac.toExponential(1)} µCi/cm³)` : ''}
              </option>
            ))}
          </select>
        </div>

        <InputField 
          id={`nuclideName-int-${radionuclide.id}`}
          label="Nuclide Name" 
          value={radionuclide.name} 
          onChange={(val) => handleFieldUpdate('name', val)}
          placeholder="e.g., Am-241 or Custom Name"
          readOnly={!isCustomSelected}
        />
        <InputField 
          id={`dacValue-int-${radionuclide.id}`}
          label="DAC Value" 
          units="µCi/cm³"
          type="text"
          value={editingDacValue} 
          onChange={setEditingDacValue}
          onBlur={() => handleNumericBlur(editingDacValue, setEditingDacValue, 'dacValue', radionuclide.dacValue)}
          readOnly={!isCustomSelected}
          helpText={isCustomSelected ? "Enter DAC manually" : "DAC from 10 CFR 835 App A"}
        />
         <InputField 
          id={`grossContam-int-${radionuclide.id}`}
          label="Gross Contamination Level" 
          units="dpm/100cm²"
          type="text"
          value={editingGrossContaminationLevel} 
          onChange={setEditingGrossContaminationLevel}
          onBlur={() => handleNumericBlur(editingGrossContaminationLevel, setEditingGrossContaminationLevel, 'grossContaminationLevel', radionuclide.grossContaminationLevel)}
        />
         <CalculatedDisplayField label="Airborne Conc." value={radionuclide.calculatedAirborneConcentration} units="µCi/cm³" />
      </div>
      
      {!isOnlyRadionuclide && (
        <button 
          type="button" 
          onClick={onRemove}
          className="absolute top-2 right-2 p-1 text-red-500 hover:text-red-700"
          aria-label="Remove internal radionuclide"
        >
          <TrashIcon className="w-5 h-5" />
        </button>
      )}
    </div>
  );
};