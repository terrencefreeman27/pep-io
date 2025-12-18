import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database service for SQLite operations
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'pep_io.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // User Profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        weight REAL,
        weight_unit TEXT,
        primary_goal TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // User Goals table
    await db.execute('''
      CREATE TABLE user_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_category TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Protocols table
    await db.execute('''
      CREATE TABLE protocols (
        id TEXT PRIMARY KEY,
        peptide_id TEXT,
        peptide_name TEXT NOT NULL,
        dosage_amount REAL NOT NULL,
        dosage_unit TEXT NOT NULL,
        frequency TEXT NOT NULL,
        days_of_week TEXT,
        times TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT,
        sync_to_calendar INTEGER DEFAULT 0,
        calendar_id TEXT,
        active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Doses table
    await db.execute('''
      CREATE TABLE doses (
        id TEXT PRIMARY KEY,
        protocol_id TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        actual_time TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols (id) ON DELETE CASCADE
      )
    ''');

    // Peptides table
    await db.execute('''
      CREATE TABLE peptides (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        alternative_names TEXT,
        category TEXT NOT NULL,
        category_color TEXT NOT NULL,
        description TEXT NOT NULL,
        benefits TEXT,
        research_protocols TEXT,
        reconstitution TEXT,
        considerations TEXT,
        storage TEXT,
        stacks_well_with TEXT,
        research_references TEXT,
        user_notes TEXT,
        is_favorite INTEGER DEFAULT 0,
        view_count INTEGER DEFAULT 0,
        last_viewed INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Calculations table
    await db.execute('''
      CREATE TABLE calculations (
        id TEXT PRIMARY KEY,
        peptide_id TEXT,
        peptide_name TEXT NOT NULL,
        vial_quantity REAL NOT NULL,
        vial_unit TEXT NOT NULL,
        water_volume REAL NOT NULL,
        syringe_type TEXT NOT NULL,
        desired_dose REAL NOT NULL,
        desired_dose_unit TEXT NOT NULL,
        concentration REAL NOT NULL,
        dose_per_unit REAL,
        volume_needed REAL NOT NULL,
        total_doses INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Onboarding Data table
    await db.execute('''
      CREATE TABLE onboarding_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intentions TEXT,
        experience_level TEXT,
        peptides_used TEXT,
        completed INTEGER DEFAULT 0,
        completed_at INTEGER
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_protocols_peptide_id ON protocols(peptide_id)');
    await db.execute('CREATE INDEX idx_protocols_active ON protocols(active)');
    await db.execute('CREATE INDEX idx_protocols_start_date ON protocols(start_date)');
    await db.execute('CREATE INDEX idx_doses_protocol_id ON doses(protocol_id)');
    await db.execute('CREATE INDEX idx_doses_scheduled_date ON doses(scheduled_date)');
    await db.execute('CREATE INDEX idx_doses_status ON doses(status)');
    await db.execute('CREATE INDEX idx_peptides_category ON peptides(category)');
    await db.execute('CREATE INDEX idx_peptides_is_favorite ON peptides(is_favorite)');
    await db.execute('CREATE INDEX idx_peptides_name ON peptides(name)');
    await db.execute('CREATE INDEX idx_calculations_peptide_id ON calculations(peptide_id)');
    await db.execute('CREATE INDEX idx_calculations_created_at ON calculations(created_at)');

    // Seed initial peptide data
    await _seedPeptideData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations for future versions
  }

  /// Seed the peptide database with initial data
  Future<void> _seedPeptideData(Database db) async {
    final peptides = _getInitialPeptideData();
    for (final peptide in peptides) {
      await db.insert('peptides', peptide);
    }
  }

  List<Map<String, dynamic>> _getInitialPeptideData() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      // GH Secretagogues Category
      _createPeptideMap(
        id: 'cjc-1295',
        name: 'CJC-1295',
        alternativeNames: ['Modified GRF 1-29', 'Mod GRF'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'CJC-1295 is a synthetic analog of growth hormone-releasing hormone (GHRH). It consists of 29 amino acids and has been studied for its ability to stimulate growth hormone secretion.',
        benefits: ['GH support', 'Recovery support', 'Body composition'],
        researchProtocols: {'dosage_range': '100-300 mcg', 'administration': 'Subcutaneous', 'duration': '8-12 weeks', 'frequency': 'Once or twice daily'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Often combined with Ipamorelin for synergistic effects. Store refrigerated after reconstitution.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['ipamorelin', 'ghrp-2'],
        now: now,
      ),
      _createPeptideMap(
        id: 'cjc-1295-dac',
        name: 'CJC-1295 DAC',
        alternativeNames: ['CJC-1295 with DAC', 'Drug Affinity Complex'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'CJC-1295 with Drug Affinity Complex (DAC) is a long-acting version of CJC-1295 that extends its half-life significantly through binding to serum albumin.',
        benefits: ['Extended GH support', 'Convenience', 'Sustained release'],
        researchProtocols: {'dosage_range': '1-2 mg', 'administration': 'Subcutaneous', 'duration': '8-12 weeks', 'frequency': 'Once or twice weekly'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '2 mg + 1 mL = 2 mg/mL'},
        considerations: 'Due to extended half-life, less frequent dosing is needed. May cause growth hormone bleed effect.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['ipamorelin'],
        now: now,
      ),
      _createPeptideMap(
        id: 'ipamorelin',
        name: 'Ipamorelin',
        alternativeNames: ['IPA'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'Ipamorelin is a pentapeptide growth hormone secretagogue (GHS) that selectively stimulates the release of growth hormone from the pituitary gland with minimal effect on cortisol and prolactin.',
        benefits: ['Selective GH release', 'Sleep support', 'Recovery'],
        researchProtocols: {'dosage_range': '100-300 mcg', 'administration': 'Subcutaneous', 'duration': '8-12 weeks', 'frequency': '2-3 times daily'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Popular choice for beginners due to selectivity. Often combined with CJC-1295.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['cjc-1295', 'cjc-1295-dac'],
        now: now,
      ),
      _createPeptideMap(
        id: 'ghrp-2',
        name: 'GHRP-2',
        alternativeNames: ['Growth Hormone Releasing Peptide-2'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'GHRP-2 is a growth hormone releasing peptide that stimulates the pituitary gland to increase growth hormone production through the ghrelin receptor.',
        benefits: ['GH release', 'Appetite support', 'Sleep quality'],
        researchProtocols: {'dosage_range': '100-300 mcg', 'administration': 'Subcutaneous', 'duration': '8-12 weeks', 'frequency': '2-3 times daily'},
        reconstitution: {'common_vial_sizes': [5.0, 10.0], 'typical_water_volume': '2-3 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'May increase appetite more than Ipamorelin due to ghrelin mimetic activity.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['cjc-1295', 'ghrp-6'],
        now: now,
      ),
      _createPeptideMap(
        id: 'ghrp-6',
        name: 'GHRP-6',
        alternativeNames: ['Growth Hormone Releasing Peptide-6'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'GHRP-6 is a growth hormone releasing hexapeptide that acts on the pituitary and hypothalamus to release growth hormone. Known for strong appetite-stimulating effects.',
        benefits: ['Strong GH release', 'Appetite stimulation', 'Recovery'],
        researchProtocols: {'dosage_range': '100-300 mcg', 'administration': 'Subcutaneous', 'duration': '8-12 weeks', 'frequency': '2-3 times daily'},
        reconstitution: {'common_vial_sizes': [5.0, 10.0], 'typical_water_volume': '2-3 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Strongest appetite stimulation of the GHRP family. Consider timing relative to meals.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['cjc-1295', 'ghrp-2'],
        now: now,
      ),
      _createPeptideMap(
        id: 'hexarelin',
        name: 'Hexarelin',
        alternativeNames: ['Examorelin'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'Hexarelin is a synthetic hexapeptide growth hormone secretagogue that is considered one of the strongest GHRP peptides for stimulating GH release.',
        benefits: ['Potent GH release', 'Cardiac support', 'Strength'],
        researchProtocols: {'dosage_range': '100-200 mcg', 'administration': 'Subcutaneous', 'duration': '4-8 weeks', 'frequency': '2-3 times daily'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '2 mg + 1 mL = 2 mg/mL'},
        considerations: 'Considered most potent GHRP. May have desensitization with prolonged use.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['cjc-1295'],
        now: now,
      ),
      _createPeptideMap(
        id: 'tesamorelin',
        name: 'Tesamorelin',
        alternativeNames: ['Egrifta'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'Tesamorelin is a growth hormone-releasing factor analog that has been studied for its effects on visceral adipose tissue in specific populations.',
        benefits: ['Visceral fat reduction', 'Lipid support', 'GH release'],
        researchProtocols: {'dosage_range': '1-2 mg', 'administration': 'Subcutaneous', 'duration': '12-26 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [1.0, 2.0], 'typical_water_volume': '0.5-1 mL', 'concentration_example': '2 mg + 1 mL = 2 mg/mL'},
        considerations: 'One of few peptides with extensive clinical research. FDA approved for specific uses.',
        storage: 'Refrigerate at 2-8°C. Reconstituted solution should be used immediately.',
        stacksWellWith: [],
        now: now,
      ),
      _createPeptideMap(
        id: 'sermorelin',
        name: 'Sermorelin',
        alternativeNames: ['GRF 1-29', 'GHRH (1-29)'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'Sermorelin is a truncated analog of growth hormone-releasing hormone (GHRH) consisting of the first 29 amino acids of GHRH.',
        benefits: ['Natural GH stimulation', 'Sleep support', 'Anti-aging research'],
        researchProtocols: {'dosage_range': '100-500 mcg', 'administration': 'Subcutaneous', 'duration': '3-6 months', 'frequency': 'Once daily, typically before bed'},
        reconstitution: {'common_vial_sizes': [3.0, 6.0, 9.0], 'typical_water_volume': '2-3 mL', 'concentration_example': '6 mg + 2 mL = 3 mg/mL'},
        considerations: 'One of the original GHRH analogs. Has clinical history of use.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 14 days.',
        stacksWellWith: ['ghrp-2', 'ghrp-6', 'ipamorelin'],
        now: now,
      ),
      _createPeptideMap(
        id: 'mk-677',
        name: 'MK-677',
        alternativeNames: ['Ibutamoren', 'Nutrobal'],
        category: 'Growth Hormone Releasing / GH Secretagogues',
        categoryColor: '#9B59B6',
        description: 'MK-677 is an orally-active growth hormone secretagogue that mimics ghrelin and stimulates the release of growth hormone and IGF-1.',
        benefits: ['Oral GH support', 'Sleep enhancement', 'Appetite increase'],
        researchProtocols: {'dosage_range': '10-25 mg', 'administration': 'Oral', 'duration': '8-16 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'N/A - Oral compound', 'concentration_example': 'N/A - Oral tablet/liquid'},
        considerations: 'Oral administration makes it unique among GH secretagogues. May increase water retention.',
        storage: 'Store in cool, dry place. No reconstitution needed.',
        stacksWellWith: [],
        now: now,
      ),
      // Body Composition Category
      _createPeptideMap(
        id: 'aod-9604',
        name: 'AOD-9604',
        alternativeNames: ['Anti-Obesity Drug 9604'],
        category: 'Body Composition / Metabolism',
        categoryColor: '#E67E22',
        description: 'AOD-9604 is a modified fragment of human growth hormone (amino acids 177-191) that has been studied for its effects on fat metabolism without affecting blood sugar.',
        benefits: ['Fat metabolism', 'No GH side effects', 'Cartilage support'],
        researchProtocols: {'dosage_range': '250-500 mcg', 'administration': 'Subcutaneous', 'duration': '12-20 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Does not affect IGF-1 levels or cause typical GH side effects. Best on empty stomach.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['bpc-157', 'tb-500'],
        now: now,
      ),
      _createPeptideMap(
        id: 'semaglutide',
        name: 'Semaglutide',
        alternativeNames: ['Ozempic', 'Wegovy', 'Rybelsus'],
        category: 'Body Composition / Metabolism',
        categoryColor: '#E67E22',
        description: 'Semaglutide is a GLP-1 receptor agonist that has been clinically studied for weight management and blood sugar regulation.',
        benefits: ['Appetite control', 'Blood sugar support', 'Weight management'],
        researchProtocols: {'dosage_range': '0.25-2.4 mg', 'administration': 'Subcutaneous weekly or oral', 'duration': '16-68 weeks', 'frequency': 'Once weekly (injection) or daily (oral)'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'Pre-filled pens', 'concentration_example': 'Varies by product'},
        considerations: 'FDA approved for specific conditions. Requires gradual dose titration. Extensive clinical research.',
        storage: 'Refrigerate unused. Can be kept at room temperature for limited time after first use.',
        stacksWellWith: [],
        now: now,
      ),
      _createPeptideMap(
        id: 'tirzepatide',
        name: 'Tirzepatide',
        alternativeNames: ['Mounjaro', 'Zepbound'],
        category: 'Body Composition / Metabolism',
        categoryColor: '#E67E22',
        description: 'Tirzepatide is a dual GIP and GLP-1 receptor agonist that has been studied for weight management and blood sugar regulation.',
        benefits: ['Dual receptor action', 'Weight management', 'Blood sugar support'],
        researchProtocols: {'dosage_range': '2.5-15 mg', 'administration': 'Subcutaneous', 'duration': '72+ weeks', 'frequency': 'Once weekly'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'Pre-filled pens', 'concentration_example': 'Varies by product'},
        considerations: 'FDA approved. Novel dual-action mechanism. Requires dose titration.',
        storage: 'Refrigerate unused. Follow product-specific storage guidelines.',
        stacksWellWith: [],
        now: now,
      ),
      _createPeptideMap(
        id: '5-amino-1mq',
        name: '5-Amino-1MQ',
        alternativeNames: ['5-amino-1-methylquinolinium'],
        category: 'Body Composition / Metabolism',
        categoryColor: '#E67E22',
        description: '5-Amino-1MQ is a small molecule that has been studied for its effects on NNMT (nicotinamide N-methyltransferase) inhibition related to fat cell metabolism.',
        benefits: ['Metabolic support', 'Fat cell regulation', 'Energy metabolism'],
        researchProtocols: {'dosage_range': '50-150 mg', 'administration': 'Oral', 'duration': '8-12 weeks', 'frequency': 'Once or twice daily'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'N/A - Oral compound', 'concentration_example': 'N/A - Capsule form'},
        considerations: 'Research compound with limited human studies. Novel mechanism of action.',
        storage: 'Store in cool, dry place away from light.',
        stacksWellWith: ['aod-9604'],
        now: now,
      ),
      _createPeptideMap(
        id: 'mots-c',
        name: 'MOTS-c',
        alternativeNames: ['Mitochondrial-derived peptide'],
        category: 'Body Composition / Metabolism',
        categoryColor: '#E67E22',
        description: 'MOTS-c is a mitochondrial-derived peptide that has been studied for its potential effects on metabolism, exercise performance, and metabolic homeostasis.',
        benefits: ['Metabolic regulation', 'Exercise performance', 'Mitochondrial support'],
        researchProtocols: {'dosage_range': '5-10 mg', 'administration': 'Subcutaneous', 'duration': '4-8 weeks', 'frequency': '3-5 times weekly'},
        reconstitution: {'common_vial_sizes': [5.0, 10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '10 mg + 2 mL = 5 mg/mL'},
        considerations: 'Novel mitochondrial peptide. Emerging research area.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: [],
        now: now,
      ),
      // Regenerative Category
      _createPeptideMap(
        id: 'bpc-157',
        name: 'BPC-157',
        alternativeNames: ['Body Protection Compound-157', 'Pentadecapeptide'],
        category: 'Regenerative / Soft Tissue Support',
        categoryColor: '#27AE60',
        description: 'BPC-157 is a synthetic peptide derived from a protective protein found in gastric juice. It consists of 15 amino acids and has been extensively studied for tissue repair and healing.',
        benefits: ['Tissue support', 'Gut balance', 'Recovery support'],
        researchProtocols: {'dosage_range': '200-500 mcg', 'administration': 'Subcutaneous or oral', 'duration': '4-12 weeks', 'frequency': 'Once or twice daily'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0, 10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'One of most researched peptides. Often combined with TB-500 for synergistic effects.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['tb-500', 'ghk-cu'],
        now: now,
      ),
      _createPeptideMap(
        id: 'tb-500',
        name: 'TB-500',
        alternativeNames: ['Thymosin Beta-4', 'Tβ4'],
        category: 'Regenerative / Soft Tissue Support',
        categoryColor: '#27AE60',
        description: 'TB-500 is a synthetic version of Thymosin Beta-4, a naturally occurring peptide present in almost all human and animal cells that plays a role in cell migration and wound healing.',
        benefits: ['Tissue repair', 'Flexibility support', 'Healing acceleration'],
        researchProtocols: {'dosage_range': '2-10 mg', 'administration': 'Subcutaneous or intramuscular', 'duration': '4-8 weeks', 'frequency': 'Twice weekly'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0, 10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Systemic action throughout body. Loading and maintenance phases often used.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Stable for 30 days.',
        stacksWellWith: ['bpc-157', 'ghk-cu'],
        now: now,
      ),
      _createPeptideMap(
        id: 'ghk-cu',
        name: 'GHK-Cu',
        alternativeNames: ['Copper Peptide GHK-Cu', 'Copper Tripeptide-1'],
        category: 'Regenerative / Soft Tissue Support',
        categoryColor: '#27AE60',
        description: 'GHK-Cu is a naturally occurring copper complex that declines with age. It has been studied for its effects on skin, wound healing, and tissue remodeling.',
        benefits: ['Skin health', 'Collagen support', 'Wound healing'],
        researchProtocols: {'dosage_range': '1-3 mg', 'administration': 'Subcutaneous or topical', 'duration': '4-12 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [50.0, 100.0, 200.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '100 mg + 2 mL = 50 mg/mL'},
        considerations: 'Available in injectable and topical forms. Copper content gives blue color.',
        storage: 'Refrigerate at 2-8°C after reconstitution. Protect from light.',
        stacksWellWith: ['bpc-157', 'tb-500'],
        now: now,
      ),
      _createPeptideMap(
        id: 'thymosin-alpha-1',
        name: 'Thymosin Alpha-1',
        alternativeNames: ['TA1', 'Tα1', 'Zadaxin'],
        category: 'Regenerative / Soft Tissue Support',
        categoryColor: '#27AE60',
        description: 'Thymosin Alpha-1 is a peptide naturally produced by the thymus gland that has been studied for its immunomodulatory properties.',
        benefits: ['Immune modulation', 'Cellular health', 'Recovery support'],
        researchProtocols: {'dosage_range': '1.5-3 mg', 'administration': 'Subcutaneous', 'duration': '4-12 weeks', 'frequency': '2-3 times weekly'},
        reconstitution: {'common_vial_sizes': [1.5, 3.0], 'typical_water_volume': '0.5-1 mL', 'concentration_example': '3 mg + 1 mL = 3 mg/mL'},
        considerations: 'Has pharmaceutical approval in some countries. Well-documented safety profile.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: ['bpc-157'],
        now: now,
      ),
      _createPeptideMap(
        id: 'epitalon',
        name: 'Epitalon',
        alternativeNames: ['Epithalon', 'Epithalamin'],
        category: 'Regenerative / Soft Tissue Support',
        categoryColor: '#27AE60',
        description: 'Epitalon is a synthetic tetrapeptide that has been studied for its potential effects on telomerase activation and pineal gland function.',
        benefits: ['Telomere support', 'Sleep regulation', 'Anti-aging research'],
        researchProtocols: {'dosage_range': '5-10 mg', 'administration': 'Subcutaneous', 'duration': '10-20 days', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [10.0, 20.0, 50.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '10 mg + 1 mL = 10 mg/mL'},
        considerations: 'Research focus on telomere biology. Often used in cycles.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: [],
        now: now,
      ),
      // Neuro/Cognitive Category
      _createPeptideMap(
        id: 'selank',
        name: 'Selank',
        alternativeNames: ['TP-7'],
        category: 'Neuro / Cognitive Support',
        categoryColor: '#3498DB',
        description: 'Selank is a synthetic peptide derived from tuftsin with added amino acids. It has been studied for its anxiolytic and nootropic properties in Russia.',
        benefits: ['Anxiety support', 'Cognitive function', 'Mood balance'],
        researchProtocols: {'dosage_range': '250-750 mcg', 'administration': 'Intranasal or subcutaneous', 'duration': '2-4 weeks', 'frequency': '1-3 times daily'},
        reconstitution: {'common_vial_sizes': [5.0], 'typical_water_volume': '1-2 mL or nasal spray', 'concentration_example': '5 mg + 2 mL = 2.5 mg/mL'},
        considerations: 'Approved in Russia. Often used intranasally for faster onset.',
        storage: 'Refrigerate at 2-8°C. Nasal preparations may have different storage requirements.',
        stacksWellWith: ['semax'],
        now: now,
      ),
      _createPeptideMap(
        id: 'semax',
        name: 'Semax',
        alternativeNames: ['Semax Nasal'],
        category: 'Neuro / Cognitive Support',
        categoryColor: '#3498DB',
        description: 'Semax is a synthetic peptide derived from ACTH (4-10) that has been studied in Russia for its neuroprotective and cognitive-enhancing properties.',
        benefits: ['Cognitive enhancement', 'Neuroprotection', 'Focus support'],
        researchProtocols: {'dosage_range': '200-1000 mcg', 'administration': 'Intranasal', 'duration': '2-4 weeks', 'frequency': '1-3 times daily'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'Typically pre-made nasal spray', 'concentration_example': '0.1% or 1% solutions'},
        considerations: 'Approved in Russia for cognitive conditions. Usually administered intranasally.',
        storage: 'Refrigerate. Follow product-specific guidelines.',
        stacksWellWith: ['selank'],
        now: now,
      ),
      _createPeptideMap(
        id: 'dsip',
        name: 'DSIP',
        alternativeNames: ['Delta Sleep-Inducing Peptide'],
        category: 'Neuro / Cognitive Support',
        categoryColor: '#3498DB',
        description: 'DSIP is a neuropeptide that was initially isolated from the blood of rabbits in an induced state of sleep. It has been studied for its effects on sleep patterns.',
        benefits: ['Sleep quality', 'Stress adaptation', 'Recovery'],
        researchProtocols: {'dosage_range': '50-200 mcg', 'administration': 'Subcutaneous or intranasal', 'duration': '2-4 weeks', 'frequency': 'Once daily before bed'},
        reconstitution: {'common_vial_sizes': [1.0, 2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '2 mg + 2 mL = 1 mg/mL'},
        considerations: 'Administered before sleep. Research on sleep architecture effects.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: ['ipamorelin'],
        now: now,
      ),
      _createPeptideMap(
        id: 'pinealon',
        name: 'Pinealon',
        alternativeNames: ['EDR peptide'],
        category: 'Neuro / Cognitive Support',
        categoryColor: '#3498DB',
        description: 'Pinealon is a short peptide (EDR) that has been studied for its effects on the pineal gland and potential neuroprotective properties.',
        benefits: ['Brain support', 'Sleep regulation', 'Neuroprotection'],
        researchProtocols: {'dosage_range': '10-20 mg', 'administration': 'Oral or subcutaneous', 'duration': '10-30 days', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [10.0, 20.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '20 mg + 2 mL = 10 mg/mL'},
        considerations: 'Part of bioregulator peptide research. Short peptide structure.',
        storage: 'Store in cool, dry place. Refrigerate after reconstitution.',
        stacksWellWith: ['epitalon'],
        now: now,
      ),
      // Skin/Hair/Beauty Category
      _createPeptideMap(
        id: 'melanotan-ii',
        name: 'Melanotan II',
        alternativeNames: ['MT-II', 'MT2'],
        category: 'Skin, Hair, Beauty',
        categoryColor: '#F39C12',
        description: 'Melanotan II is a synthetic analog of alpha-melanocyte stimulating hormone that has been studied for its effects on skin pigmentation.',
        benefits: ['Tanning support', 'Libido effects', 'Appetite effects'],
        researchProtocols: {'dosage_range': '100-500 mcg', 'administration': 'Subcutaneous', 'duration': '4-8 weeks', 'frequency': 'Once daily or every other day'},
        reconstitution: {'common_vial_sizes': [10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '10 mg + 2 mL = 5 mg/mL'},
        considerations: 'May cause nausea initially. Start with low doses. UV exposure typically needed.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: [],
        now: now,
      ),
      _createPeptideMap(
        id: 'pt-141',
        name: 'PT-141',
        alternativeNames: ['Bremelanotide', 'Vyleesi'],
        category: 'Skin, Hair, Beauty',
        categoryColor: '#F39C12',
        description: 'PT-141 is a synthetic peptide derived from Melanotan II that has been studied and approved for certain sexual dysfunction conditions.',
        benefits: ['Libido support', 'Sexual function', 'Central mechanism'],
        researchProtocols: {'dosage_range': '1-2 mg', 'administration': 'Subcutaneous', 'duration': 'As needed', 'frequency': 'Single dose as needed'},
        reconstitution: {'common_vial_sizes': [10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '10 mg + 2 mL = 5 mg/mL'},
        considerations: 'FDA approved for specific conditions. Works through CNS rather than vascular system.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: [],
        now: now,
      ),
      _createPeptideMap(
        id: 'argireline',
        name: 'Argireline',
        alternativeNames: ['Acetyl Hexapeptide-8', 'Acetyl Hexapeptide-3'],
        category: 'Skin, Hair, Beauty',
        categoryColor: '#F39C12',
        description: 'Argireline is a hexapeptide that has been studied for its effects on reducing the appearance of wrinkles by inhibiting neurotransmitter release.',
        benefits: ['Anti-wrinkle', 'Expression line reduction', 'Skin smoothing'],
        researchProtocols: {'dosage_range': '5-10% concentration', 'administration': 'Topical', 'duration': 'Ongoing', 'frequency': 'Once or twice daily'},
        reconstitution: {'common_vial_sizes': [], 'typical_water_volume': 'N/A - Topical', 'concentration_example': '5-10% in serum'},
        considerations: 'Topical cosmetic ingredient. Often called "Botox in a bottle" though mechanism differs.',
        storage: 'Store per product guidelines. Typically room temperature.',
        stacksWellWith: ['ghk-cu'],
        now: now,
      ),
      // Muscle/Strength Category
      _createPeptideMap(
        id: 'igf-1-lr3',
        name: 'IGF-1 LR3',
        alternativeNames: ['Long R3 IGF-1', 'IGF-1 Long Arg3'],
        category: 'Muscle / Strength / Recovery',
        categoryColor: '#C0392B',
        description: 'IGF-1 LR3 is a modified version of IGF-1 with an extended half-life. It has been studied for its anabolic properties and effects on muscle growth.',
        benefits: ['Muscle growth', 'Recovery support', 'Anabolic effects'],
        researchProtocols: {'dosage_range': '20-100 mcg', 'administration': 'Subcutaneous or intramuscular', 'duration': '4-6 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [0.1, 1.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '1 mg + 1 mL = 1 mg/mL'},
        considerations: 'Potent growth factor. Often cycled due to potential for receptor desensitization.',
        storage: 'Refrigerate at 2-8°C. Very sensitive to degradation. Use acetic acid for reconstitution.',
        stacksWellWith: ['peg-mgf'],
        now: now,
      ),
      _createPeptideMap(
        id: 'follistatin-344',
        name: 'Follistatin 344',
        alternativeNames: ['FS-344', 'FST-344'],
        category: 'Muscle / Strength / Recovery',
        categoryColor: '#C0392B',
        description: 'Follistatin 344 is a single-domain glycoprotein that has been studied for its ability to bind and neutralize myostatin, potentially affecting muscle growth.',
        benefits: ['Myostatin inhibition', 'Muscle potential', 'Strength support'],
        researchProtocols: {'dosage_range': '100-300 mcg', 'administration': 'Subcutaneous', 'duration': '10-30 days', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [1.0], 'typical_water_volume': '1 mL', 'concentration_example': '1 mg + 1 mL = 1 mg/mL'},
        considerations: 'Research peptide with limited human data. Expensive and delicate.',
        storage: 'Refrigerate at 2-8°C. Very fragile - avoid freezing and repeated freeze-thaw.',
        stacksWellWith: ['igf-1-lr3'],
        now: now,
      ),
      _createPeptideMap(
        id: 'peg-mgf',
        name: 'PEG-MGF',
        alternativeNames: ['PEGylated Mechano Growth Factor'],
        category: 'Muscle / Strength / Recovery',
        categoryColor: '#C0392B',
        description: 'PEG-MGF is a PEGylated form of Mechano Growth Factor, a splice variant of IGF-1 that has been studied for its effects on muscle repair and growth.',
        benefits: ['Muscle repair', 'Satellite cell activation', 'Recovery'],
        researchProtocols: {'dosage_range': '200-400 mcg', 'administration': 'Intramuscular', 'duration': '4-6 weeks', 'frequency': '2-3 times weekly'},
        reconstitution: {'common_vial_sizes': [2.0, 5.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '2 mg + 1 mL = 2 mg/mL'},
        considerations: 'PEGylation extends half-life compared to regular MGF. Often used post-workout.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: ['igf-1-lr3', 'bpc-157'],
        now: now,
      ),
      // Longevity Category
      _createPeptideMap(
        id: 'humanin',
        name: 'Humanin',
        alternativeNames: ['HN', 'HNG'],
        category: 'Longevity / Systemic Peptides',
        categoryColor: '#16A085',
        description: 'Humanin is a mitochondrial-derived peptide that has been studied for its potential cytoprotective and longevity-related properties.',
        benefits: ['Cellular protection', 'Mitochondrial support', 'Longevity research'],
        researchProtocols: {'dosage_range': '1-4 mg', 'administration': 'Subcutaneous', 'duration': '4-8 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [5.0, 10.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '10 mg + 2 mL = 5 mg/mL'},
        considerations: 'Emerging research area in longevity science. Mitochondrial-derived peptide family.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: ['mots-c', 'epitalon'],
        now: now,
      ),
      _createPeptideMap(
        id: 'ss-31',
        name: 'SS-31',
        alternativeNames: ['Elamipretide', 'Bendavia', 'MTP-131'],
        category: 'Longevity / Systemic Peptides',
        categoryColor: '#16A085',
        description: 'SS-31 is a mitochondria-targeted peptide that has been studied for its ability to stabilize cardiolipin in the inner mitochondrial membrane.',
        benefits: ['Mitochondrial function', 'Cellular energy', 'Cardiac support'],
        researchProtocols: {'dosage_range': '10-40 mg', 'administration': 'Subcutaneous', 'duration': '4-12 weeks', 'frequency': 'Once daily'},
        reconstitution: {'common_vial_sizes': [10.0, 50.0], 'typical_water_volume': '1-2 mL', 'concentration_example': '50 mg + 2 mL = 25 mg/mL'},
        considerations: 'Has undergone clinical trials. Focus on mitochondrial membrane support.',
        storage: 'Refrigerate at 2-8°C after reconstitution.',
        stacksWellWith: ['humanin', 'mots-c'],
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _createPeptideMap({
    required String id,
    required String name,
    required List<String> alternativeNames,
    required String category,
    required String categoryColor,
    required String description,
    required List<String> benefits,
    required Map<String, String> researchProtocols,
    required Map<String, dynamic> reconstitution,
    required String considerations,
    required String storage,
    required List<String> stacksWellWith,
    required int now,
  }) {
    return {
      'id': id,
      'name': name,
      'alternative_names': alternativeNames.toString().replaceAll(RegExp(r'[\[\]]'), '').isEmpty 
          ? '[]' 
          : '["${alternativeNames.join('","')}"]',
      'category': category,
      'category_color': categoryColor,
      'description': description,
      'benefits': '["${benefits.join('","')}"]',
      'research_protocols': '{"dosage_range":"${researchProtocols['dosage_range']}","administration":"${researchProtocols['administration']}","duration":"${researchProtocols['duration']}","frequency":"${researchProtocols['frequency']}"}',
      'reconstitution': '{"common_vial_sizes":${reconstitution['common_vial_sizes']},"typical_water_volume":"${reconstitution['typical_water_volume']}","concentration_example":"${reconstitution['concentration_example']}"}',
      'considerations': considerations,
      'storage': storage,
      'stacks_well_with': stacksWellWith.isEmpty ? '[]' : '["${stacksWellWith.join('","')}"]',
      'research_references': '[]',
      'user_notes': null,
      'is_favorite': 0,
      'view_count': 0,
      'last_viewed': null,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing/reset)
  Future<void> deleteDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

