
import React, { useState, useCallback } from 'react';
import { TaskCard } from './components/TaskCard.js';
import { 
  TaskData, 
  GlobalFactors, 
  RadionuclideAnalysis, 
  SectionAData, 
  SectionBData, 
  SectionCData,
  SectionEData, 
  InternalDoseScenarioData,
  SectionKData,
  SectionMData, 
  SectionFData,
  SectionFRadionuclideData,
  RespiratoryProtectionFactorEnum, 
  EngineeringProtectionFactorEnum 
} from './types.js';
import { PlusIcon } from './components/icons.js';
import { INITIAL_RADIONUCLIDES_COUNT } from './constants.js';

const App: React.FC = () => {
  const [tasks, setTasks] = useState<TaskData[]>([]);
  // GlobalFactors is now minimal, could be used for other app-wide settings if needed
  const [globalFactors, setGlobalFactors] = useState<GlobalFactors>({});
  const [wcdNumber, setWcdNumber] = useState<string>('');
  const [rwpNumber, setRwpNumber] = useState<string>('');

  const createNewTask = (): TaskData => {
    const taskId = `task-${Date.now()}`;
    
    const initialInternalRadionuclides: RadionuclideAnalysis[] = [];
    for (let i = 0; i < INITIAL_RADIONUCLIDES_COUNT; i++) {
        initialInternalRadionuclides.push({
            id: `nuc-int-${taskId}-${i}-${Date.now()}`,
            radionuclideKey: 'custom', 
            name: '', 
            dacValue: 0, 
            grossContaminationLevel: 0,
            calculatedAirborneConcentration: null,
            calculatedCA_EngControls: null,
        });
    }

    const initialSectionFRadionuclides: SectionFRadionuclideData[] = [{
      id: `nuc-secF-${taskId}-0-${Date.now()}`,
      radionuclideKey: 'custom',
      name: '',
      timePerWorkerHours: 0,
      extremitySkinDoseRate: 0,
      calculatedExtremitySkinDose: null,
    }];

    const defaultInternalDoseScenario: InternalDoseScenarioData = {
      radionuclideContributions: [],
      totalInternalExposureWithoutResp: null,
      totalInternalExposureWithResp: null,
      isRespiratoryProtectionPrescribed: false,
      explanation: '',
    };

    return {
      id: taskId,
      title: `New Task ${tasks.length + 1}`,
      
      // External Dose Group
      sectionB: { location: '', numWorkers: 0, hoursPerWorker: 0, calculatedPersonHours: null } as SectionBData,
      sectionC: { directExposureRate: 0, calculatedExternalExposure: null } as SectionCData,
      sectionE: { directHandling: false, shieldedGloveboxWork: false, shieldingLeaks: false, nonUniformMaterials: false, protectiveClothingLeadedGarments: false, rsoDeemedNecessary: false } as SectionEData,
      sectionF: { radionuclides: initialSectionFRadionuclides, totalExposurePerIndividual: null, isDosimetryPrescribed: false, comments: '' } as SectionFData,
      
      // Internal Dose Group
      sectionA: { r: 0, c: 0, d: 0, o: 0, s: 0, u: 0, calculatedMPIF: null } as SectionAData,
      radionuclidesInternal: initialInternalRadionuclides,
      
      respiratoryProtectionFactorValue: RespiratoryProtectionFactorEnum.None,
      engineeringProtectionFactorValue: EngineeringProtectionFactorEnum.TypeI,
      engineeringControlsUsed: false, 
      
      internalDoseWithoutEngControls: { ...defaultInternalDoseScenario, radionuclideContributions: initialInternalRadionuclides.map(n => ({ radionuclideId: n.id, internalExposureNoResp: null, internalExposureWithResp: null })) },
      internalDoseWithEngControls: { ...defaultInternalDoseScenario, radionuclideContributions: initialInternalRadionuclides.map(n => ({ radionuclideId: n.id, internalExposureNoResp: null, internalExposureWithResp: null })) },
                                                
      sectionK: { 
        radionuclideDacFractions: initialInternalRadionuclides.map(n => ({ radionuclideId: n.id, dacFraction: null })),
        totalDacFraction: null, 
        isAirSamplingRequiredOver03DAC: false,
        isAreaPostedARA: false,
        comments: '' 
      } as SectionKData,
      sectionM: { externalExposure: null, internalExposure: null, effectiveDose: null } as SectionMData,
    };
  };

  const addTask = () => {
    setTasks(prevTasks => [...prevTasks, createNewTask()]);
  };

  const updateTask = useCallback((updatedTask: TaskData) => {
    setTasks(prevTasks => prevTasks.map(task => task.id === updatedTask.id ? updatedTask : task));
  }, []);

  const removeTask = (taskId: string) => {
    setTasks(prevTasks => prevTasks.filter(task => task.id !== taskId));
  };
  
  // Note: handleGlobalFactorChange is no longer needed for PFR/PFE
  // It could be repurposed if other true global factors are introduced.

  const totalEffectiveDoseAllTasks = tasks.reduce((sum, task) => sum + (task.sectionM.effectiveDose || 0), 0);

  return (
    <div className="min-h-screen bg-slate-100 p-4 md:p-8">
      <header className="mb-8 text-center">
        <img src="https://www.anl.gov/sites/www.anl.gov/files/ArgonneLogoStandardRGB.png" alt="Argonne National Laboratory" className="h-16 mx-auto mb-4"/>
        <h1 className="text-4xl font-bold text-blue-700">Effective Dose Assessment Worksheet</h1>
        <p className="text-slate-600">Based on RPP-742 (Revised Flow)</p>
      </header>

      <div className="max-w-6xl mx-auto bg-white p-6 rounded-xl shadow-2xl">
        {/* Document Info */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8 pb-6 border-b border-slate-300">
          <div>
            <label htmlFor="wcdNumber" className="block text-sm font-medium text-slate-700">WCD Number</label>
            <input 
              type="text" 
              id="wcdNumber"
              value={wcdNumber}
              onChange={(e) => setWcdNumber(e.target.value)}
              className="mt-1 form-input block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2" 
              placeholder="e.g., 71057"
            />
          </div>
          <div>
            <label htmlFor="rwpNumber" className="block text-sm font-medium text-slate-700">RWP Number</label>
            <input 
              type="text" 
              id="rwpNumber"
              value={rwpNumber}
              onChange={(e) => setRwpNumber(e.target.value)}
              className="mt-1 form-input block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2"
              placeholder="e.g., 2024-203-026"
            />
          </div>
        </div>

        {/* Task List */}
        <div className="space-y-6">
          {tasks.map((task) => ( 
            <TaskCard 
              key={task.id} 
              task={task}
              globalFactors={globalFactors} // Pass if any true global factors exist
              onUpdateTask={updateTask}
              onRemoveTask={() => removeTask(task.id)} 
            />
          ))}
        </div>

        <button 
          type="button" 
          onClick={addTask}
          className="mt-8 flex items-center justify-center w-full px-6 py-3 border-2 border-dashed border-blue-400 text-blue-600 font-medium rounded-lg hover:bg-blue-50 hover:border-blue-600 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <PlusIcon className="w-6 h-6 mr-2" /> Add New Task
        </button>

        {tasks.length > 0 && (
            <div className="mt-12 pt-6 border-t border-slate-300">
                <h2 className="text-2xl font-semibold text-blue-700 mb-4">Overall Job Summary</h2>
                <div className="bg-blue-50 p-6 rounded-lg shadow">
                    <p className="text-lg font-medium text-slate-700">
                        Total Job Effective Dose: 
                        <span className="font-bold text-blue-600 ml-2">
                            {totalEffectiveDoseAllTasks.toExponential(4)} mrem
                        </span>
                    </p>
                    <p className="text-sm text-slate-500">This is the sum of 'Effective Dose' from Section M for all tasks.</p>
                </div>
            </div>
        )}
      </div>

      <footer className="text-center mt-12 text-sm text-slate-500">
        <p>This tool is for estimation purposes. Always consult with a qualified Health Physicist.</p>
        <p>Argonne National Laboratory - RPP-742 Digitized Aid</p>
      </footer>
    </div>
  );
};

export default App;