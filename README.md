# Decentralized Supply Chain Risk Management

A set of Clarity smart contracts for managing supply chain risks in a decentralized manner.

## Overview

This project provides a comprehensive solution for supply chain risk management using blockchain technology. It consists of five main contracts that work together to verify entities, assess risks, monitor conditions, manage alerts, and track mitigation efforts.

## Contracts

### Entity Verification Contract

Validates supply chain participants by:
- Registering new entities with pending status
- Allowing admins to verify or reject entities
- Tracking verification status and dates

### Risk Assessment Contract

Identifies potential disruption factors by:
- Defining risk factors with severity, probability, and impact
- Assigning risks to specific entities
- Categorizing risks for better management

### Monitoring Contract

Tracks conditions affecting the supply chain by:
- Defining monitoring parameters with thresholds
- Recording monitoring data over time
- Detecting threshold breaches

### Alert Management Contract

Handles notification of potential issues by:
- Creating alerts with different severity levels
- Tracking alert status (active, acknowledged, resolved)
- Linking alerts to entities, parameters, and risks

### Mitigation Tracking Contract

Records actions to address risks by:
- Creating mitigation plans with deadlines
- Tracking individual mitigation actions
- Monitoring completion status of plans and actions

## Usage

### Entity Verification

```clarity
;; Register a new entity
(contract-call? .entity-verification register-entity "supplier-123" "Acme Supplies" "supplier")

;; Verify an entity (admin only)
(contract-call? .entity-verification verify-entity "supplier-123" u1)
