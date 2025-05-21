
import React, { useState, useEffect, useCallback } from 'react';
import type { SectionFRadionuclideData } from '../types.js';
import { RADIONUCLIDE_DAC_LIST } from '../radionuclideData.js'; // Re-use for name consistency
import { TrashIcon } from './icons.js';

interface SectionFRadionuclideRowProps {
  radionuclide: SectionFRadionuclideData;
  onUpdate: (updatedRadionuclide: SectionFRadionuclideData) => void;
  onRemove: () => void;
  isOnlyRadionuclide: boolean;
  parentId: string; // To make input IDs unique
}

// Basic InputField (can be further DRYed up with RadionuclideRow's if needed)
const InputField: React.FC<{ 
  label: string; 
  value: string | number; // Changed to string for editing state
  onChange: (value: string) => void; 
  onBlur?: () => void; // Added onBlur
  type?: string; 
  units?: string; 
  id: string;
  readOnly?: boolean;
  placeholder?: string;
}> = ({ label, value, onChange, onBlur, type = "text", units, id, readOnly = false, placeholder }) => (
  <div className="flex flex-col space-y-1">
    <label htmlFor={id} className="text-sm font-medium text-slate-700">{label} {units && <span className="text-xs text-slate-500">({units})</span>}</label>
    <input
      id={id}
      type={type} // Use "text" for fields that have local string editing state
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onBlur={onBlur}
      placeholder={placeholder}
      readOnly={readOnly}
      className={`form-input block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 ${readOnly ? 'bg-slate-100 cursor-not-allowed' : 'bg-white'}`}
      aria-readonly={readOnly}
    />
  </div>
);

const CalculatedDisplayField: React.FC<{ label: string; value: number | string | null; units?: string; precision?: number }> = 
  ({ label, value, units, precision = 2 }) => (
  <div className="flex flex-col space-y-1">
    <span className="text-sm font-medium text-slate-700">{label} {units && <span className="text-xs text-slate-500">({units})</span>}</span>
    <span className="text-sm p-2 min-h-[2.5rem] flex items-center bg-slate-50 rounded-md border border-slate-200">
      {typeof value === 'number' ? value.toFixed(precision) : (value ?? 'N/A')}
    </span>
  </div>
);

export const SectionFRadionuclideRow: React.FC<SectionFRadionuclideRowProps> = ({ radionuclide, onUpdate, onRemove, isOnlyRadionuclide, parentId }) => {
  
  const [editingTimePerWorker, setEditingTimePerWorker] = useState<string>(String(radionuclide.timePerWorkerHours ?? ''));
  const [editingDoseRate, setEditingDoseRate] = useState<string>(String(radionuclide.extremitySkinDoseRate ?? ''));

  useEffect(() => {
    setEditingTimePerWorker(String(radionuclide.timePerWorkerHours ?? ''));
  }, [radionuclide.timePerWorkerHours]);

  useEffect(() => {
    setEditingDoseRate(String(radionuclide.extremitySkinDoseRate ?? ''));
  }, [radionuclide.extremitySkinDoseRate]);
  
  const calculateDose = useCallback(() => {
    let newCalculatedDose: number | null = null;
    if (radionuclide.timePerWorkerHours > 0 && radionuclide.extremitySkinDoseRate > 0) {
      newCalculatedDose = radionuclide.timePerWorkerHours * radionuclide.extremitySkinDoseRate;
    }

    if (radionuclide.calculatedExtremitySkinDose !== newCalculatedDose) {
      onUpdate({
        ...radionuclide,
        calculatedExtremitySkinDose: newCalculatedDose,
      });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [radionuclide.timePerWorkerHours, radionuclide.extremitySkinDoseRate, radionuclide.calculatedExtremitySkinDose]);

  useEffect(() => {
    calculateDose();
  }, [calculateDose]);

  const handleFieldUpdate = <K extends keyof SectionFRadionuclideData>(field: K, value: SectionFRadionuclideData[K]) => {
    onUpdate({ ...radionuclide, [field]: value });
  };
  
  const handleNumericBlur = (
    editingValue: string,
    setter: (val: string) => void,
    modelField: keyof SectionFRadionuclideData,
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

      if (!isCustom) {
        newName = selectedEntry.displayName; 
      }
  
      onUpdate({
        ...radionuclide,
        radionuclideKey: selectedKey,
        name: newName,
      });
    }
  };
  
  const isCustomSelected = radionuclide.radionuclideKey === 'custom';
  const baseId = `${parentId}-${radionuclide.id}`;

  return (
    <div className="p-4 border border-slate-300 rounded-lg bg-white shadow space-y-4 relative">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div>
          <label htmlFor={`secF-nuclideKey-${baseId}`} className="text-sm font-medium text-slate-700">Select Radionuclide</label>
          <select
            id={`secF-nuclideKey-${baseId}`}
            value={radionuclide.radionuclideKey}
            onChange={handleRadionuclideKeyChange}
            className="mt-1 form-select block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 bg-white"
          >
            {RADIONUCLIDE_DAC_LIST.map(entry => (
              <option key={entry.key} value={entry.key}>
                {entry.displayName}
              </option>
            ))}
          </select>
        </div>

        <InputField 
          id={`secF-nuclideName-${baseId}`}
          label="Nuclide Name (for Sec F)" 
          value={radionuclide.name} 
          onChange={(val) => handleFieldUpdate('name', val)}
          placeholder="e.g., Co-60 Hot Particle"
          readOnly={!isCustomSelected}
        />
        <InputField 
          id={`secF-timePerWorker-${baseId}`}
          label="Time per worker" 
          units="hours"
          type="text" // Use text for smoother editing
          value={editingTimePerWorker} 
          onChange={setEditingTimePerWorker}
          onBlur={() => handleNumericBlur(editingTimePerWorker, setEditingTimePerWorker, 'timePerWorkerHours', radionuclide.timePerWorkerHours)}
        />
         <InputField 
          id={`secF-doseRate-${baseId}`}
          label="Extremity/Skin Dose Rate" 
          units="mrem/hr"
          type="text" // Use text for smoother editing
          value={editingDoseRate} 
          onChange={setEditingDoseRate}
          onBlur={() => handleNumericBlur(editingDoseRate, setEditingDoseRate, 'extremitySkinDoseRate', radionuclide.extremitySkinDoseRate)}
        />
        <CalculatedDisplayField label="Extremity/Skin Dose" value={radionuclide.calculatedExtremitySkinDose} units="mrem" />
      </div>
      
      {!isOnlyRadionuclide && (
        <button 
          type="button" 
          onClick={onRemove}
          className="absolute top-2 right-2 p-1 text-red-500 hover:text-red-700"
          aria-label="Remove radionuclide for Section F"
        >
          <TrashIcon className="w-5 h-5" />
        </button>
      )}
    </div>
  );
};