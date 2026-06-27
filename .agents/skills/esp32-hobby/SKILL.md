---
name: esp32-hobby
description: "Use when working on ESP32/ESP-IDF hobby projects with OpenCode agents: firmware, FreeRTOS, debugging, IO testing, UI, hardware bring-up, safe flashing/OTA, and portable documentation."
version: 1.0.0
author: EspAgent
license: MIT
metadata:
  hermes:
    tags: [esp32, esp-idf, opencode, firmware, freertos, hobby]
    related_skills: []
---

# ESP32 Hobby Skill Pack

## Overview

This skill pack is for practical ESP32 hobby projects. It supports a multi-agent workflow where agents read this skill before making assumptions about firmware delivery, hardware testing, documentation, or safety.

## When to Use

Use this skill when:
- building or modifying an ESP32 / ESP-IDF project;
- debugging boot/panic/runtime/peripheral problems;
- validating GPIO/I2C/SPI/UART/PWM/ADC points;
- planning USB flash, OTA, or serial-monitor work;
- documenting wiring, APIs, build steps, or test plans.

## Core Rules

1. Inspect project facts first: chip target, ESP-IDF version, build wrapper, pin map, and hardware scope.
2. Build before flash/OTA.
3. Keep logs bounded.
4. Keep project docs portable: no user-home paths, build artifacts, downloaded tools, or secrets.
5. Prefer ESP-IDF APIs and existing project style.
6. Treat hardware tests as real side effects.

## Reference Files

- `references/usb-programming-and-downloads.md` — USB flash, OTA, tool downloads, serial monitor.
- `references/documentation.md` — portable command-first docs.

## Verification Checklist

- [ ] Project root and chip target identified.
- [ ] ESP-IDF/build workflow identified.
- [ ] Relevant source/docs read.
- [ ] Build or safe check run, or explicit NOT RUN reason given.
- [ ] Hardware actions require explicit approval.
- [ ] Serial/log capture bounded.
- [ ] No local user paths/secrets/tool installs committed.
