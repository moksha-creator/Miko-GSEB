# Miko × GSEB Classroom Assessment Demo

This monorepo contains the demo applications for the Miko AI classroom assessment system, built for the Gujarat State Government.

## Repository Structure

- `packages/shared_core/`: Contains the mock JSON data, shared models, themes, and services.
- `packages/student_ipad/`: The student-facing iPad assessment experience.
- `packages/teacher_phone/`: The teacher's control panel and dashboard.

## Running the Apps

### Prerequisites
- Flutter SDK
- Melos (`dart pub global activate melos`)

### Setup
1. Clone the repository and navigate to the root directory.
2. Run `melos bootstrap` to install all dependencies and link the packages.

### Running Teacher Phone
1. Open a terminal and navigate to `packages/teacher_phone`.
2. Run `flutter run -d <simulator_id>` (Use an iPhone or Android phone simulator).

### Running Student iPad
1. Open a terminal and navigate to `packages/student_ipad`.
2. Run `flutter run -d <simulator_id>` (Use an iPad simulator).
   *Note: Ensure the simulator is rotated to landscape mode.*

---

## 30-Second Demo Flow

### Teacher Phone App
1. **Onboarding**: Start the app. You'll see the first step of the onboarding wizard. Tap **Demo mode: use sample class** at the bottom to skip directly to the populated dashboard.
2. **Today Tab**: You will see the current session in progress ("Fractions"). Note the animated "In progress" status for Aarav Patel and the orange warning banner for a flagged student.
3. **Start Session**: Tap the floating **Start session on smart board** button. A snackbar will confirm connection. (At this point, you gesture to the iPad app).
4. **Class Tab**: Switch to the Class tab to show the progression matrix (L1-L4 colors) across subjects for all 40 students.
5. **Reports Tab**: Switch to the Reports tab to show the generated CP2 report, highlighting class-wide weaknesses and the individual profile breakdown.

### Student iPad App
1. **Mode Select**: Start the app. The screen is locked to landscape. You will see two large cards.
2. **Walkthrough Mode (For quick visual overview)**: 
   - Tap **Walkthrough Mode**.
   - Tap anywhere on the screen to progress through the visual stages of the assessment flow (Greeting -> Subject -> Question -> Listening -> Evaluating -> Branching -> Closing).
   - This mode does not play audio, making it easy to narrate over.
3. **Live Session Mode (For realistic feel)**:
   - Tap **Live Session Mode**.
   - Wait 2 seconds for the mock face recognition to complete.
   - The AI will speak (using pre-generated TTS audio) and show subtitled text.
   - When the AI asks a question, a button **Tap when Aarav finishes answering** will appear at the bottom. Tap it to simulate the student finishing their response.
   - The AI will show a thinking state and then ask a follow-up question.
   - Tap the button again.
   - A subtle green glow will indicate a "Level Up" moment (developer demo feature), followed by the closing statement.
   - A final summary modal will appear.
