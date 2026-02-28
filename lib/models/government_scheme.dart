import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  SchemeCategory  –  categorises a [GovernmentScheme]
// ══════════════════════════════════════════════════════════

enum SchemeCategory {
  insurance,
  boatSubsidy,
  fuelSubsidy,
  disasterCompensation;

  String get label {
    switch (this) {
      case SchemeCategory.insurance:
        return 'Insurance';
      case SchemeCategory.boatSubsidy:
        return 'Boat Subsidy';
      case SchemeCategory.fuelSubsidy:
        return 'Fuel Subsidy';
      case SchemeCategory.disasterCompensation:
        return 'Disaster Compensation';
    }
  }

  IconData get icon {
    switch (this) {
      case SchemeCategory.insurance:
        return Icons.health_and_safety;
      case SchemeCategory.boatSubsidy:
        return Icons.sailing;
      case SchemeCategory.fuelSubsidy:
        return Icons.local_gas_station;
      case SchemeCategory.disasterCompensation:
        return Icons.emergency;
    }
  }

  Color get color {
    switch (this) {
      case SchemeCategory.insurance:
        return Colors.teal;
      case SchemeCategory.boatSubsidy:
        return Colors.indigo;
      case SchemeCategory.fuelSubsidy:
        return Colors.orange;
      case SchemeCategory.disasterCompensation:
        return Colors.red;
    }
  }
}

// ══════════════════════════════════════════════════════════
//  GovernmentScheme  –  immutable data class
// ══════════════════════════════════════════════════════════

class GovernmentScheme {
  final String name;
  final String description;
  final SchemeCategory category;
  final String ministry;
  final String eligibility;
  final List<String> benefits;
  final String howToApply;
  final String? website;

  const GovernmentScheme({
    required this.name,
    required this.description,
    required this.category,
    required this.ministry,
    required this.eligibility,
    required this.benefits,
    required this.howToApply,
    this.website,
  });
}

// ══════════════════════════════════════════════════════════
//  Built-in catalogue  –  fully offline, hard-coded
// ══════════════════════════════════════════════════════════

const governmentSchemes = <GovernmentScheme>[
  // ── Insurance Schemes ──────────────────────────────────
  GovernmentScheme(
    name: 'Pradhan Mantri Suraksha Bima Yojana (PMSBY)',
    description: 'Accidental death & disability insurance cover of ₹2 lakh at '
        'a premium of just ₹20/year for fishermen aged 18–70.',
    category: SchemeCategory.insurance,
    ministry: 'Ministry of Finance',
    eligibility:
        'All fishermen aged 18–70 with a bank account and Aadhaar card.',
    benefits: [
      '₹2 lakh for accidental death',
      '₹2 lakh for total permanent disability',
      '₹1 lakh for partial permanent disability',
    ],
    howToApply:
        'Visit any nationalised bank branch or apply through the PM-SBY portal. '
        'Link your Aadhaar and bank account for auto-debit of ₹20.',
    website: 'https://jansuraksha.gov.in',
  ),
  GovernmentScheme(
    name: 'Pradhan Mantri Jeevan Jyoti Bima Yojana (PMJJBY)',
    description: 'Life insurance cover of ₹2 lakh at ₹436/year premium for '
        'fishermen aged 18–50.',
    category: SchemeCategory.insurance,
    ministry: 'Ministry of Finance',
    eligibility: 'All Indian citizens aged 18–50 with a bank account.',
    benefits: [
      '₹2 lakh death benefit (any cause)',
    ],
    howToApply:
        'Enrol through bank branch, net-banking, or PM Jan Dhan portal. '
        'Annual premium of ₹436 auto-debited from linked bank account.',
    website: 'https://jansuraksha.gov.in',
  ),
  GovernmentScheme(
    name: 'National Scheme of Welfare of Fishermen',
    description: 'Group accident insurance for active fishermen during the '
        'fishing season, funded by the Central Government.',
    category: SchemeCategory.insurance,
    ministry: 'Ministry of Fisheries, Animal Husbandry & Dairying',
    eligibility: 'Active marine and inland fishermen below poverty line (BPL). '
        'Must possess a valid fishing licence.',
    benefits: [
      '₹2 lakh for accidental death at sea',
      '₹1 lakh for permanent total disability',
      'House-building assistance up to ₹75,000',
      'Savings-cum-relief during lean/ban season: ₹3,000',
    ],
    howToApply: 'Apply through the District Fisheries Officer (DFO) or State '
        'Fisheries Department. No premium required from the fisherman.',
    website: 'https://dof.gov.in',
  ),

  // ── Boat Subsidy Schemes ───────────────────────────────
  GovernmentScheme(
    name: 'PMMSY – Vessel Modernisation',
    description: 'Up to 60 % subsidy (₹40 lakh cap) on the cost of new '
        'deep-sea fishing vessels with modern navigation and safety equipment.',
    category: SchemeCategory.boatSubsidy,
    ministry: 'Ministry of Fisheries, Animal Husbandry & Dairying',
    eligibility:
        'Registered fishermen, Fish Farmer Producer Organisations (FFPOs), '
        'and cooperatives. Priority for SC/ST/women beneficiaries.',
    benefits: [
      '40 % general subsidy (60 % for SC/ST/women)',
      'Covers hull, engine, winch, GPS, VHF radio',
      'Includes safety kit (life jackets, flares, EPIRB)',
    ],
    howToApply:
        'Submit application on the PMMSY e-portal (pmmsy.dof.gov.in) with '
        'vessel drawings, cost estimate, BPL/caste certificate.',
    website: 'https://pmmsy.dof.gov.in',
  ),
  GovernmentScheme(
    name: 'Motorization of Traditional Craft',
    description: 'Subsidy up to ₹1 lakh for fitting outboard motors (OBM) on '
        'non-motorised traditional boats to improve range, safety, and catch.',
    category: SchemeCategory.boatSubsidy,
    ministry: 'Ministry of Fisheries / State Fisheries Dept.',
    eligibility:
        'Owners of traditional non-motorised craft (catamaran, canoe, vallam) '
        'with a valid fishing licence.',
    benefits: [
      'Up to ₹1 lakh subsidy on OBM purchase + fitting',
      'Additional ₹10,000 for propeller & shaft installation',
    ],
    howToApply:
        'Contact the District Fisheries Office. Submit vessel registration, '
        'fishing licence, and quotation from authorised OBM dealer.',
  ),
  GovernmentScheme(
    name: 'FRP Boat Distribution Scheme',
    description:
        'State-level scheme distributing Fibre Reinforced Plastic (FRP) '
        'boats to BPL fishermen at subsidised cost or free.',
    category: SchemeCategory.boatSubsidy,
    ministry: 'State Fisheries Departments',
    eligibility: 'BPL fishermen who do not own a mechanised/motorised boat. '
        'Preference for coastal SC/ST fisher families.',
    benefits: [
      'Free or heavily subsidised FRP boat (24–32 ft)',
      'Includes fishing nets and basic gear',
    ],
    howToApply: 'Apply at the Taluk/Block Fisheries Office with BPL card, '
        'fishing licence, and Aadhaar. Selected through lottery in some states.',
  ),

  // ── Fuel Subsidy Schemes ───────────────────────────────
  GovernmentScheme(
    name: 'Diesel Subsidy for Fishing Boats',
    description: 'Central/State subsidy providing diesel at reduced rates to '
        'mechanised fishing vessels.',
    category: SchemeCategory.fuelSubsidy,
    ministry: 'Ministry of Fisheries / State Governments',
    eligibility:
        'Registered mechanised and motorised fishing vessels operating '
        'from notified fishing harbours and landing centres.',
    benefits: [
      'OBM boats: up to 500 L/trip at ₹10/L discount',
      'Mechanised boats: up to 3,000 L/trip at ₹10/L discount',
      'Deep-sea vessels: up to 5,000 L/trip at ₹12/L discount',
    ],
    howToApply: 'Obtain a "Fuel Card" from the District Fisheries Officer. '
        'Present it at designated fuel bunks/harbour fuel depots.',
  ),
  GovernmentScheme(
    name: 'Kerosene Subsidy for Fishermen',
    description:
        'Subsidised kerosene distribution for traditional fishing boats '
        'that use kerosene-powered lanterns for night fishing.',
    category: SchemeCategory.fuelSubsidy,
    ministry: 'State Civil Supplies / Fisheries Dept.',
    eligibility:
        'Active fishermen with traditional craft engaged in night fishing. '
        'Must hold ration card + fishing licence.',
    benefits: [
      'Subsidised kerosene up to 15 L/month per household',
      'PDS rate (approximately ₹25/L vs market ₹90/L)',
    ],
    howToApply:
        'Approach nearest Fair Price Shop with fishing licence, ration card, '
        'and Aadhaar-linked household ID.',
  ),

  // ── Disaster Compensation ──────────────────────────────
  GovernmentScheme(
    name: 'SDRF / NDRF Compensation for Fishermen',
    description:
        'Immediate relief under State/National Disaster Response Fund for '
        'fishermen affected by cyclones, floods, and storm surges.',
    category: SchemeCategory.disasterCompensation,
    ministry: 'National/State Disaster Management Authority',
    eligibility: 'Fishermen who suffered loss of life, livelihood, or property '
        'due to a declared natural disaster.',
    benefits: [
      '₹4 lakh ex-gratia for death',
      '₹2 lakh for severe injury/disability',
      'Up to ₹4,100/month for livelihood loss (up to 3 months)',
      '₹5,200 for fully damaged fishing net',
      'Up to ₹10,000 for damaged boat (non-motorised)',
    ],
    howToApply:
        "File claim with the District Collector's office within 30 days of "
        'the disaster. Attach FIR/death certificate, boat registration, '
        'and damage assessment report from Block Development Office.',
  ),
  GovernmentScheme(
    name: 'PMMSY – Disaster Risk Mitigation',
    description:
        'Financial assistance for replacing boats/nets destroyed in natural '
        'disasters, and for installing weather-warning communication equipment.',
    category: SchemeCategory.disasterCompensation,
    ministry: 'Ministry of Fisheries, Animal Husbandry & Dairying',
    eligibility: 'Fishermen who lost boats/equipment in a declared disaster. '
        'Must have registered vessel and valid fishing licence.',
    benefits: [
      'Up to ₹5 lakh for mechanised boat replacement',
      'Up to ₹1.5 lakh for traditional boat replacement',
      'Up to ₹25,000 for fishing gear/net replacement',
      'Subsidised VHF radio and NAVIC receiver installation',
    ],
    howToApply: 'Apply via pmmsy.dof.gov.in or State Fisheries Department with '
        'damage assessment, vessel registration, and disaster certificate.',
    website: 'https://pmmsy.dof.gov.in',
  ),
  GovernmentScheme(
    name: 'Saving-cum-Relief during Ban Period',
    description:
        'Cash relief of ₹3,000–₹4,500 for the 47-day monsoon fishing ban '
        'when fishing is prohibited to protect breeding stocks.',
    category: SchemeCategory.disasterCompensation,
    ministry: 'Ministry of Fisheries / State Fisheries Dept.',
    eligibility:
        'Active marine fishermen affected by the annual monsoon fishing ban. '
        "Must have saved ₹1,500 in the scheme's savings component.",
    benefits: [
      '₹3,000 relief (₹1,500 own savings + ₹1,500 govt contribution)',
      'Some states top up to ₹4,500 total',
    ],
    howToApply:
        'Register at the District Fisheries Office before the ban season. '
        'Deposit ₹1,500 in the designated savings account. '
        'Relief disbursed directly to bank account during the ban.',
  ),
];
