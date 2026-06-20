# UI/UX guide

## Goal

This document describes the visual and UX direction for the swirl Android app.

The app should feel friendly, soft, simple, and motivating for beginner English learners.

## General style

The visual style should be:

- soft
- friendly
- cartoon-like
- clean
- colorful but not aggressive
- easy to understand
- suitable for beginners and younger users

The app should not feel like a strict corporate or complex education system.

## Design principles

Use these principles:

- simple screens
- large readable text
- clear primary action on each screen
- friendly illustrations or icons where possible
- rounded cards and buttons
- visible progress
- minimal cognitive load
- smooth transitions
- understandable empty and error states

## Color direction

Use a light theme.

Dark theme is not required for MVP.

Recommended color feel:

- light background
- soft accent colors
- friendly green/blue/purple/yellow tones
- avoid harsh red except for error states
- avoid too many saturated colors on one screen

Color roles:

- primary color for main buttons and active elements
- secondary color for cards or decorative elements
- success color for correct answers and completed levels
- error color for wrong answers and validation errors
- neutral colors for text, borders, and disabled states

## Typography

Typography should be readable on Android smartphones.

Rules:

- use large headings for screen titles
- use medium text for labels and cards
- use clear body text for descriptions
- avoid very small text
- avoid long paragraphs in UI
- use consistent font sizes

Recommended text hierarchy:

- screen title
- section title
- card title
- body text
- hint text
- error text

## Spacing

Use generous spacing.

Rules:

- avoid crowded screens
- keep enough padding inside cards
- keep enough margin between sections
- make touch targets comfortable
- make lists scrollable when needed
- avoid overflow on small screens

## Components

Use reusable components for:

- primary button
- secondary button
- text input
- password input
- avatar item
- section card
- level item/node
- word card
- exercise option button
- progress bar
- loading state
- error state
- empty state
- result pop-up

## Buttons

Primary button:

- used for main action
- visually prominent
- rounded corners
- clear label

Secondary button:

- used for alternative action
- less prominent than primary button

Disabled button:

- clearly disabled
- should not look clickable

Button labels should be short and clear.

Examples:

- Log in
- Sign up
- Continue
- Start
- Learn words
- Start training
- Try again
- Back to map

## Forms

Forms should be simple and friendly.

Rules:

- show one clear label or hint per field
- validate required fields
- show errors near the field
- password fields should hide input by default
- forms must work when the keyboard is open
- login and signup should show API errors clearly

Login fields:

- email
- password

Sign up fields:

- name
- email
- password
- confirm password

Avatar selection is not shown on the sign up screen in Stage 2. The app assigns
a random predefined avatar during registration. The user may change avatar later
from profile/settings when that flow is implemented.

## Loading states

Every API screen should have a loading state.

Loading states should be friendly and not alarming.

Use loading states for:

- app startup
- login
- signup
- profile loading
- sections loading
- levels loading
- words loading
- level session loading
- daily test loading

## Error states

Error states should be understandable.

Rules:

- do not show raw exception text
- explain what happened in simple language
- provide retry button when possible
- redirect to login on authentication errors

Example messages:

```text
Something went wrong. Please try again.
Check your internet connection and try again.
This level is locked.
Learn more words to unlock the daily test.
```

## Empty states

Use empty states when there is no data.

Examples:

- no sections available
- no levels available
- no words in level
- daily test unavailable
- profile statistics are empty

Empty states should explain what the user can do next.

## Home page

Home page should contain:

- greeting
- profile avatar icon
- daily test card
- continue learning block
- short progress summary
- button or card to open all sections

UX goals:

- user immediately understands what to do next
- daily test is visible but not intrusive
- progress feels motivating

## Profile screen

Profile should contain:

- user name
- avatar
- current streak
- best streak
- learned words count
- completed levels count
- section progress
- logout button

UX rules:

- statistics should be easy to scan
- logout button should not be too prominent
- profile data must be clearly connected to current user

## Sections screen

Sections screen should show:

- section title
- section image or icon
- short description
- progress percent
- completed levels count
- navigation to level map

MVP sections:

- Food
- Science
- Health
- Wardrobe

## Level map

Level map should show level states clearly:

- locked
- available
- completed
- current

UX rules:

- locked levels should look disabled
- completed levels should look rewarding
- available levels should invite action
- final test should be visually distinguishable but can use same interaction flow

## Level pop-up

Level pop-up should show:

- section title
- level number
- CEFR level
- short description
- words count
- exercises count
- button to learn words
- button to start training if words are already learned

If words are not learned, the primary action should lead to Learn words.

## Learn word screen

Learn word screen should show:

- English word
- Russian translation
- transcription
- part of speech if available
- image
- audio play button
- progress through words
- next button

UX rules:

- focus on one word at a time
- make audio button easy to find
- image should be large enough
- user should always know how many words are left

## Exercises

Exercise screens should show:

- progress through tasks
- question
- image or audio if needed
- input field or answer options
- check/continue action
- correct or incorrect state

UX rules:

- one task per screen
- avoid distractions
- options should be easy to tap
- answer state should be clear
- correct answer should not be shown immediately after a mistake in MVP

## Result pop-ups

Level win pop-up should feel positive and rewarding.

Show:

- success message
- mistakes count
- finish button back to the current section levels

Lose pop-up should be supportive, not punishing.

Show:

- failed attempt message
- mistakes count
- try again button
- back to current section levels button

## Daily test

Daily test should reuse existing exercise UI where possible.

Unavailable daily test message:

```text
Изучите больше слов, чтобы открыть ежедневный тест
```

Daily test result should show:

- correct answers count
- total answers count
- streak update if changed

## Accessibility and usability

MVP should still be comfortable to use.

Rules:

- touch targets should be large enough
- text should be readable
- color should not be the only way to show state
- buttons should have clear labels
- forms should have clear errors
- screens should scroll if content does not fit

## Android screen support

The app should work on different Android smartphones.

Minimum requirements:

- no major overflow
- content fits small screens through scrolling
- keyboard does not hide important form fields
- images scale correctly
- cards and lists remain readable

Tablet-specific layout is not required in MVP.

## Animations

Use simple animations only if they do not slow development.

Recommended:

- standard route transitions
- button feedback
- small progress animations
- simple loading animation

Do not add complex animations unless explicitly requested.

## Out of scope for MVP

Do not implement unless explicitly requested:

- dark theme
- tablet-specific design
- advanced animations
- custom illustration system
- full accessibility audit
- localization system
- user theme customization
