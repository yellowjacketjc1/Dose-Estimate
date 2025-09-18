# Dose Estimation Tool - Changelog

## Version 2.0.0 - Major Feature Enhancement (2024-12-26)

### 🚀 New Features

#### User Interface Improvements
- **Removed Project Name Field**: Streamlined project information section by removing redundant project name field
- **Updated Work Order Label**: Changed "Work Order Number" to "Work Control Document Number" for regulatory compliance
- **Added Task Location Field**: Added building and room number input for each task with summary table display
- **Improved Task Naming**: Fixed task placeholder text from "undefined" to "Write task name here"

#### Enhanced Dose Calculations
- **Per-Nuclide Internal Dose Display**:
  - Individual internal dose calculation and display for each radionuclide
  - Collective internal dose calculation and display for each radionuclide
  - Individual DAC fraction display for each radionuclide
  - Total DAC fraction sum across all radionuclides per task
- **Improved Dose Formula**:
  - Fixed DAC fraction calculation to properly account for engineering protection factors (PFE)
  - Updated dose calculation to use person-hours instead of individual hours
  - Corrected protection factor application: DAC fraction ÷ PFE, dose calculation ÷ PFR

#### Enhanced Summary Table
- **Expanded Summary Display**: Added comprehensive dose information per task:
  - Task name and location
  - Number of workers
  - **DAC Fraction per task** (sum of all radionuclide DAC fractions)
  - Individual external dose (mrem)
  - Individual internal dose (mrem)
  - **Collective external dose (mrem)**
  - **Collective internal dose (mrem)**
  - Total individual dose (mrem)

#### Automated Safety Compliance
- **Auto-Check ALARA Controls**: Automatically checks ALARA trigger boxes when:
  - Individual dose estimate > 500 mrem per year
  - DAC-hours > 200 or DAC spike > 1000
  - Contamination levels > 1000x Appendix D levels
  - Dose rate > 10 rem/hr (10,000 mrem/hr)

### 🔧 Technical Improvements

#### Updated Regulatory Data
- **DAC Values**: Updated to conservative values from 10 CFR 835 Appendix A
  - Sr-90: Updated to 9E-9 µCi/mL
  - U-235: Updated to 8E-11 µCi/mL
  - Cs-137: Updated to 4E-9 µCi/mL (more conservative)
  - Co-60: Updated to 2E-9 µCi/mL (more conservative)
  - Am-241: Updated to 2E-12 µCi/mL (more conservative)
  - And many other radionuclides with more conservative values

#### Formula Corrections
- **Air Concentration**: Maintained existing correct formula
- **DAC Fraction**: Now properly divided by Engineering Protection Factor (PFE)
- **Internal Dose**: Uses corrected formula with person-hours and proper protection factor application
- **Collective vs Individual**: Clear distinction between collective and individual dose calculations

#### Data Management
- **Save/Load Functionality**: Updated to include new task location field
- **Summary Calculations**: Enhanced to support new dose display requirements
- **Auto-checking Logic**: Implemented comprehensive condition checking for safety triggers

### 📊 Summary Table Enhancement

The main summary page now provides a comprehensive overview:
- **9 columns** of detailed information per task
- **Real-time DAC fraction calculation** showing sum of all radionuclides per task
- **Both individual and collective dose display** for complete exposure assessment
- **Location tracking** for better work planning and dose ALARA considerations

### ⚡ User Experience
- **Improved Visual Layout**: Better spacing and organization of task sections
- **Enhanced Data Display**: More comprehensive dose breakdown per radionuclide
- **Automated Compliance**: Reduced manual checkbox management with auto-checking
- **Better Task Management**: Location-based task organization

### 🔒 Regulatory Compliance
- **10 CFR 835 Appendix A**: Updated DAC values for conservative dose estimation
- **ALARA Principles**: Automated trigger identification for dose optimization
- **Documentation**: Enhanced work control document number tracking

---

## Commit Messages for Git

### Recommended commit structure:

```bash
git add .
git commit -m "Major dose estimation tool enhancement v2.0.0

- Remove project name field from project information
- Change Work Order to Work Control Document Number
- Add location field (building/room) for each task
- Fix task placeholder text (undefined → Write task name here)
- Implement per-nuclide internal dose calculations with individual display
- Show DAC fraction for each radionuclide and total per task
- Update DAC values to conservative 10 CFR 835 Appendix A values
- Auto-check ALARA controls based on dose/DAC/contamination/dose rate thresholds
- Enhance summary table with DAC fraction, individual, and collective doses
- Fix dose calculation formulas for proper protection factor application
- Update radionuclide dose calculation to use person-hours

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Individual feature commits (if preferred):

1. **UI/UX Improvements**:
   ```
   feat: streamline project info and improve task management

   - Remove project name field
   - Change Work Order to Work Control Document Number
   - Add task location field with building/room number
   - Fix task placeholder text display
   ```

2. **Dose Calculation Enhancement**:
   ```
   feat: implement comprehensive per-nuclide dose calculations

   - Add individual internal dose display per radionuclide
   - Show DAC fraction for each radionuclide
   - Calculate collective internal dose per radionuclide
   - Fix dose formula to use person-hours and proper protection factors
   ```

3. **Regulatory Data Update**:
   ```
   feat: update DAC values to 10 CFR 835 Appendix A conservative values

   - Update Sr-90 to 9E-9 µCi/mL
   - Update U-235 to 8E-11 µCi/mL
   - Apply more conservative values for Cs-137, Co-60, Am-241, and others
   ```

4. **Summary Enhancement**:
   ```
   feat: enhance summary table with comprehensive dose information

   - Add DAC fraction column per task
   - Show both individual and collective doses
   - Include location information in summary
   - Expand to 9-column detailed view
   ```

5. **Safety Automation**:
   ```
   feat: implement automated ALARA control checking

   - Auto-check when individual dose > 500 mrem
   - Auto-check when DAC-hrs > 200 or spike > 1000 DAC
   - Auto-check when contamination > 1000x Appendix D
   - Auto-check when dose rate > 10 rem/hr
   ```