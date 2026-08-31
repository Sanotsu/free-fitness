<p align="right">
  <a href="README.md">简体中文</a> |
  <a href="README-en.md">English</a>
</p>

# Free-Fitness

## Description

Free-Fitness is a comprehensive fitness and nutrition management application developed with Flutter, integrating features for exercise training, dietary recording, and journaling.

This application serves as an auxiliary tool for individuals with requirements for fitness training, weight management (loss/muscle gain), dietary tracking, and quick note-taking. All data is stored locally.

- 2025-08-01: For immediate usability, versions `0.2.2-beta.1` and subsequent releases may include built-in data:
  - "Exercises": Sourced from the GitHub repository [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db), utilizing exercise data and images from the forked repository
  - "Food Composition": Nutritional data from "China Food Composition Table Standard Edition (6th Edition)" [Sanotsu/china-food-composition-data](https://github.com/Sanotsu/china-food-composition-data)
  - **Note**: Built-in data initialization only occurs during first-time installation. Upgrading or restoring the app without uninstallation will not trigger data initialization
    - Users can manually load built-in data via the "Load Built-in Data" option in the top-right corner of the "Exercises" and "Food Composition" homepages, which will replace existing data with identical names/codes
    - 2026-08-31: **Updated the built-in food composition data to the latest version**

## Updates

- 2026-08-31 `0.2.3-beta.1`
  - Brand-new "AI Assistant" module: user-configured LLM API, 5 built-in specialized roles + custom role management, and unified AI analysis entries for diet journal / meal photos / training groups / plans
  - Backup restore supports module-based (user/diet/journal/training/AI) selective merge restore with progress display
  - Updated the built-in food composition data to the latest version
- 2025-08-01 `0.2.2-beta.1`
  - Incorporated built-in "Exercises" and "Food Composition" data for immediate use
- 2024-12-03 `0.2.1-beta.1`
  - Integrated 01.AI's large language model API for AI-powered analysis of dietary records and meal photos, providing interactive recommendations

For additional changes, refer to [CHANGELOG](CHANGELOG.md)

## Feature Overview

Maintaining a healthy physique primarily requires appropriate exercise and nutrition management.

Key application features include:

![Main Interface Screenshot](_screenshots/1主页面截图.jpg)

### Exercise Module

Users can manually add or batch import exercise movements in specified JSON format to create training sessions and plans. For example:

- First create or import (some are built-in) **Training Actions**, such as seated leg raises, crunches, bicycle kicks, seated twists
- Then create a **Training Group**, e.g., "Abdominal Workout", adding these actions: seated leg raises for 30 seconds × 5 sets, crunches 20 reps × 3 sets, etc.
- With sufficient training groups, users can organize a **Training Plan**, such as Day 1 "Abdominal Training", Day 2 "Leg Training", Day 3 "Chest Training", etc.

With established "Training" or "Training Plans", users can select specific content for **guided workouts**, with the app providing countdown timers for each movement.

#### Exercises

**Swipe left to delete** items in the list.

Users can import JSON files (details below) or manually add exercises. Fewer items display in table format. Exercise details can be viewed or modified at any time.

![Exercise Module Functions](_screenshots/2动作模块基本功能.jpg)

#### Training Sets

**Long press to delete** training lists and plan lists.

After creating a training session, users must add specific exercises with configurations. The interface displays time or repetitions based on whether the exercise is timed or counted, with options for equipment/weight additions.

When modifying exercises within a training session, long press to reorder, delete button to remove items, and tap items to adjust duration/repetitions and weight configurations.

![Basic Training Module Functions](_screenshots/3训练模块基本功能.jpg)

#### Periodic Plans

The plan module functions similarly to training - after creating basic plan information, users add existing training sessions.

**A plan consists of training groups, and a training group consists of exercises.**

![Basic Plan Module Functions](_screenshots/4计划模块基本功能.jpg)

#### Guided Workout Interface

After selecting a specific training session or training day from a plan, users can begin guided workouts with simple TTS voice prompts.

- Note: A TTS engine is required for voice prompts; devices without a TTS engine can still follow along normally, just without voice (a one-time notice appears when entering the guided workout page)
- Training group lists, plan lists, and each training day within a plan display an "estimated duration", calculated in real time from exercise configurations and the rest-interval setting, consistent with the actual guided workout execution

Countdown duration corresponds to configured exercise times: timed exercises use set durations directly, while counted exercises calculate duration as `repetitions × standard movement completion time`.

Users can skip or repeat exercises during workouts, and restart completed sessions. Each completion generates a basic training report.

![Guided Workout Interface](_screenshots/5跟练训练的页面.jpg)

#### Exercise Reports

Exercise reports statistics include each workout's name, duration, etc. Reports can be exported as PDF files when needed.

![Exercise Report Interface](_screenshots/6运动报告页面.jpg)

### Nutrition Module

The nutrition module provides similar functionality:

- First requires food and nutritional data (**Food Composition** module)
- Then record daily meals (four meals: three main + snacks) with food selections and quantities (**Diet Journal** module)
- Option to photograph or select gallery images for simple meal documentation (**Meal Gallery** module)
- Finally, statistical analysis of food and nutrient intake over time periods to assess health compliance (**Diet Report** module)

#### Food Composition

The food composition list (partially built-in) displays basic food information, but nutritional values per serving may vary. For example, one serving could be `100g at 200 kcal` while another is `1 piece at 300 kcal`. Multiple serving options display more clearly in table format.

Food composition primarily involves adding nutritional information, either via specified JSON format (details below) or manual entry.

**Long press to delete** specific foods (no batch deletion currently available)

![Food Module Interface](_screenshots/7食物模块页面.jpg)

The food detail page allows modifications to food information and nutritional values per serving.

Two serving unit types are available: standard `100g/100ml` measurements or flexible `1 serving` units.

After selecting specific nutritional data, users can modify or delete entries. Currently, imported foods don't include image import logic, so food images can be modified here.

![Food Detail Interface](_screenshots/8食物详情页面.jpg)

#### Diet Journal

Diet recording is a core feature for documenting daily intake across four meals (three main meals plus snacks/other consumption).

By selecting specific foods and inputting quantities (with corresponding nutritional data), users can estimate daily caloric intake. Simple statistics and charts are provided. The calendar button (top-right) displays daily energy intake for better dietary management.

Photos can be uploaded for each meal to document consumption, viewable later in the meal gallery.

**For days with dietary records, tap the chat icon (bottom-right) for AI analysis**:

- Transmits daily food/nutrient intake data to the AI Assistant for analysis with the Dietitian role, supporting simple multi-turn dialogue
- When the day's intake data is unchanged, re-entering only shows the previous analysis without calling the LLM again

![Basic Diet Recording Functions](_screenshots/9饮食记录基本功能.jpg)

#### Meal Gallery

Centralized browsing of saved meal images, with options to select gallery photos or take new pictures.

AI image analysis is also available from either the diet record photo page or the meal gallery:

- Analyzed by the AI Assistant with the Dietitian role, supporting up to 4 images at once
- Requires the model enabled in "LLM Configuration" to support vision (verifiable via "Test Vision" on the configuration page); unchanged photos of the same meal will not trigger repeated calls

![Meal Gallery Interface](_screenshots/10餐食相册页面.jpg)

#### Diet Reports

Beyond daily statistics below diet records, comprehensive dietary intake statistics display consumption patterns over periods (up to two weeks), including food variety/frequency/quantity and major nutrient intake.

Reports can also be exported as PDF files for specified ranges.

![Diet Report Interface](_screenshots/11饮食报告页面.jpg)

### Journal Module

The journal (diary) module was initially added for quick supplementary recording. For example: "Ran 10km today, ate a roast chicken" - when app-generated reports aren't needed.

The journal features a rich text editor for flexible information recording, including image support.

![Journal Interface](_screenshots/12手记页面.jpg)

### AI Assistant Module

New general-purpose AI assistant introduced in `0.2.3-beta.1`, accessible via the floating button on the home page; business entries (Diet Journal / Meal Photos / Training Groups / Periodic Plans) also jump in with context.

- **Self-configured LLM API**: add any OpenAI-compatible platform's endpoint and API key under "User & Settings" - "More Settings" - "LLM Configuration"; multiple configurations can be saved and switched at any time. Each configuration independently selects the model, vision support, and advanced parameters, with "Test Connection" / "Test Vision" provided
- **Role system**: 5 built-in roles — Assistant, Health Assistant, Dietitian, Fitness Coach, and Weight Advisor (each with its own setup and suggested questions); built-in roles are view-only, and custom roles can be added
- **General chat**: streaming responses, multi-image upload (up to 4), conversation history management (switch/rename/clear/delete), and token usage display
- **Business conversation reuse**: the same business object (same day's diet / same meal's photos / same training group / same plan) reuses one conversation; when the data is unchanged, only the previous analysis is shown, and a new analysis is appended automatically after changes
- **Backup & restore**: LLM configurations and conversation images are included in the module-based backup/restore

## User & Settings

Primarily handles user information management, weight records, daily intake goals, backup/restore, language/theme switching, etc.

Backups export all database data to JSON files compressed into ZIP packages. Restorable files don't strictly require app-generated ZIPs - any properly formatted ZIP will work.

Since `0.2.3-beta.1`, restore supports **module-based (user/diet/journal/training/AI) selective merge restore** — restore only the parts you need; LLM configurations and conversation images are also included in backup/restore.

**Note: Before uninstalling or upgrading, perform a full backup first; after reinstallation, perform a merge restore first.**

English language and dark theme support isn't fully implemented - some discrepancies may exist.

![User & Settings](_screenshots/13用户与设置.jpg)

## Usage Instructions

2025-08-01: Versions `0.2.0-beta.1` and later require internet connectivity, but only for online AI model API calls and exercise/food image loading.

### Limited Permissions

~~The app operates offline,~~ but requests storage access for PDF export and backup/restore functions. Denying permission only disables these features without affecting others.

- 2025-08-01: Added AI analysis for diet records requires internet connectivity for API calls.
- 2026-08-31: Since `0.2.3-beta.1`, the AI platform is user-configured (any OpenAI-compatible platform). Without AI configured, all features work normally; AI analysis entries will just guide you to the configuration page.

### Sensitive Information

~~The app operates entirely offline with all data stored locally in cached SQLite databases. Even network image URLs may not load (code exclusively uses `File(path)`).~~

- 2025-08-01: As above, except built-in exercise images load from GitHub URLs. All other data remains local, ensuring privacy.

### Data Formats

For the exercise module's crucial "**Action**" data, refer to this GitHub repository [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) for full compatibility.

For convenience, two additional fields can be included: `countingMode` (timed or counted) to distinguish timing/counting modes, and `standardDuration` indicating time required per standard movement in counted mode.

Defaults to `timed` and `1` second if unspecified.

```json
[
  {
    "id": "Sit-Up",
    "name": "Sit Up",
    "force": "pull",
    "level": "beginner",
    "mechanic": "isolation",
    "equipment": "body only",
    "primaryMuscles": ["abdominals"],
    "secondaryMuscles": [],
    "instructions": [
      "Lie flat on the ground with feet secured under a stable object or by a partner, knees bent.",
      "Cross hands behind head as starting position.",
      "Raise upper body to form an imaginary V-shape with thighs, exhaling during movement.",
      "Hold contracted position for 1 second, then slowly inhale while returning to start.",
      "Repeat for recommended repetitions."
    ],
    "category": "strength",
    "images": ["Sit-Up/0.jpg", "Sit-Up/1.jpg"],
    "countingMode": "counted",
    "standardDuration": "2"
  }
  //...
]
```

Note: Exercise images can include multiple files, with paths relative to the image folder.

When uploading, select the image folder corresponding to the relative paths in the `images` field (the common path prefix). Otherwise, only the relative paths will be stored without proper image association.

- For online image URLs in the data, simply import the JSON without selecting image folders

**Special Note for 2025-08-01**

The code specifically matches JSON structures from [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db). Therefore, the following fields must use English enumeration values matching the repository's JSON to ensure proper querying and display:

Refer to constant definitions in [constants.dart](lib/core/constants/constants.dart) for bilingual values.

Imported JSON must use these **English enumeration values** from `free-exercise-db` for specified fields:

- force
  - pull, push, static, other
- level
  - beginner, intermediate, expert
- mechanic
  - isolation, compound
- category
  - strength, stretching, plyometrics, power lifting,
  - strongman, cardio, anaerobic, other
- equipment
  - body, body only, barbell, dumbbell, cable,
  - kettlebells, bands, medicine ball, exercise ball, foam roll,
  - e-z curl bar, machine, other
- primaryMuscles or secondaryMuscles
  - quadriceps, shoulders, abdominals, chest, hamstrings,
  - triceps, biceps, lats, middle back, calves,
  - lower back, forearms, glutes, trapezius, adductors,
  - abductors, neck, other
- countingMode
  - counted, timed

Reference: [Value options in yuhonas/free-exercise-db](https://lite.datasette.io/?json=https://github.com/yuhonas/free-exercise-db/blob/main/dist/exercises.json#/data/exercises?_facet_array=primaryMuscles&_facet_array=secondaryMuscles&_facet=force&_facet=level&_facet=mechanic&_facet=equipment&_facet=primaryMuscles&_facet=category).

---

For the nutrition module's crucial "**Food Composition**" data, no equivalent repository was found. Instead, we processed screenshots from the PDF version of ["China Food Composition Table Standard Edition (6th Edition)"](https://www.pumpedu.com/home-shop/5514.html), specifically the "Energy and General Food Nutrients" section, using Python scripts to generate specified JSON format files. Test data is available on GitHub [Sanotsu/china-food-composition-data](https://github.com/Sanotsu/china-food-composition-data).

The actual JSON format doesn't require all fields - the following suffices (additional fields are unused):

**(Values default to 100g edible portion nutritional information)**

```json
[
  {
    "foodCode": "091101x",
    "foodName": "Chicken (representative value)",
    "energyKCal": "145",
    "energyKJ": "608",
    "protein": "20.3",
    "fat": "6.7",
    "CHO": "0.9",
    "dietaryFiber": "0.0",
    "cholesterol": "106",
    "Na": "62.8",
    "tags": "Meat",
    "category": "Non-vegetarian",
    "photos": [
      "<full_device_path>/0.jpg",
      "<full_device_path_temporarily_unused>/0.jpg"
    ]
  }
  // ...
]
```

- For data not following "China Food Composition Table Standard Edition (6th Edition)" structure, use `foodCode` for "food brand" and `foodName` for "food name".

Exercise and food composition JSON can also use single-entry JSON files. Non-array data will be automatically wrapped.

Improper formatting or duplicate data will prevent import (typically duplicate exercise/food names).

## Additional Notes

### Android Exclusive

No support for other devices currently available.

Initially developed for personal use on primary device Nubia Z60Ultra (Android 14) and secondary Xiaomi 6 (Android 12), both with 1080P full screens. Display discrepancies may occur on other devices - please provide feedback or modify accordingly.

### Known Issues

<details>

<summary>Potential existing issues (incomplete list)</summary>

- Incomplete adaptation for English language and dark theme
- Many database operations lack try-catch error handling
- Inconsistent coding patterns for similar logic
- Retained unused component code blocks, commented code, and print statements

Development prioritized releasing a test version by 2023, leading to rushed implementation. Continuous improvements are planned.

</details>

---

For any questions or suggestions, please don't hesitate to provide feedback. Thank you.

——Translated by DeepSeek V1
