-- Seed: production-categories.sql
-- Description: Insert production-ready category structure for Colombian PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Clear existing demo categories (keep structure)
DELETE FROM categories WHERE slug NOT IN ('electronicos', 'oficina', 'hogar', 'deportes', 'salud');

-- ==================== MAIN CATEGORIES ====================

-- Update existing categories with better descriptions
UPDATE categories SET 
    description = 'Productos electrónicos, tecnológicos y de telecomunicaciones',
    icon = 'fas fa-microchip',
    color = '#3498db'
WHERE slug = 'electronicos';

UPDATE categories SET 
    description = 'Suministros, equipos y mobiliario de oficina',
    icon = 'fas fa-briefcase',
    color = '#2ecc71'
WHERE slug = 'oficina';

UPDATE categories SET 
    description = 'Productos para el hogar, limpieza y cuidado personal',
    icon = 'fas fa-home',
    color = '#e74c3c'
WHERE slug = 'hogar';

UPDATE categories SET 
    description = 'Artículos deportivos, recreativos y de entretenimiento',
    icon = 'fas fa-futbol',
    color = '#f39c12'
WHERE slug = 'deportes';

UPDATE categories SET 
    description = 'Productos de salud, farmacia y cuidado médico',
    icon = 'fas fa-heartbeat',
    color = '#9b59b6'
WHERE slug = 'salud';

-- Add new main categories
INSERT INTO categories (name, slug, description, icon, color, sort_order) VALUES
('Alimentos y Bebidas', 'alimentos-bebidas', 'Productos alimenticios, bebidas y suplementos nutricionales', 'fas fa-utensils', '#27ae60', 6),
('Ropa y Textiles', 'ropa-textiles', 'Prendas de vestir, calzado y productos textiles', 'fas fa-tshirt', '#8e44ad', 7),
('Construcción y Ferretería', 'construccion-ferreteria', 'Materiales de construcción, herramientas y ferretería', 'fas fa-hammer', '#34495e', 8),
('Automotriz', 'automotriz', 'Repuestos, accesorios y productos para vehículos', 'fas fa-car', '#e67e22', 9),
('Belleza y Cuidado Personal', 'belleza-cuidado', 'Productos de belleza, cosméticos y cuidado personal', 'fas fa-spa', '#ff69b4', 10),
('Libros y Papelería', 'libros-papeleria', 'Libros, material educativo y artículos de papelería', 'fas fa-book', '#795548', 11),
('Mascotas', 'mascotas', 'Productos para mascotas, alimentos y accesorios', 'fas fa-paw', '#ff9800', 12),
('Jardín y Exterior', 'jardin-exterior', 'Productos para jardín, plantas y actividades al aire libre', 'fas fa-seedling', '#4caf50', 13);

-- ==================== ELECTRONICS SUBCATEGORIES ====================

-- Get electronics category ID
DO $$
DECLARE
    cat_electronicos UUID;
    cat_oficina UUID;
    cat_hogar UUID;
    cat_deportes UUID;
    cat_salud UUID;
    cat_alimentos UUID;
    cat_ropa UUID;
    cat_construccion UUID;
    cat_automotriz UUID;
    cat_belleza UUID;
    cat_libros UUID;
    cat_mascotas UUID;
    cat_jardin UUID;
BEGIN
    SELECT id INTO cat_electronicos FROM categories WHERE slug = 'electronicos';
    SELECT id INTO cat_oficina FROM categories WHERE slug = 'oficina';
    SELECT id INTO cat_hogar FROM categories WHERE slug = 'hogar';
    SELECT id INTO cat_deportes FROM categories WHERE slug = 'deportes';
    SELECT id INTO cat_salud FROM categories WHERE slug = 'salud';
    SELECT id INTO cat_alimentos FROM categories WHERE slug = 'alimentos-bebidas';
    SELECT id INTO cat_ropa FROM categories WHERE slug = 'ropa-textiles';
    SELECT id INTO cat_construccion FROM categories WHERE slug = 'construccion-ferreteria';
    SELECT id INTO cat_automotriz FROM categories WHERE slug = 'automotriz';
    SELECT id INTO cat_belleza FROM categories WHERE slug = 'belleza-cuidado';
    SELECT id INTO cat_libros FROM categories WHERE slug = 'libros-papeleria';
    SELECT id INTO cat_mascotas FROM categories WHERE slug = 'mascotas';
    SELECT id INTO cat_jardin FROM categories WHERE slug = 'jardin-exterior';

    -- ELECTRONICS SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Computadoras y Laptops', 'computadoras-laptops', 'Computadores de escritorio, laptops y workstations', cat_electronicos, 'fas fa-laptop', '#3498db', 1),
    ('Teléfonos y Tablets', 'telefonos-tablets', 'Smartphones, tablets y accesorios móviles', cat_electronicos, 'fas fa-mobile-alt', '#1abc9c', 2),
    ('Audio y Video', 'audio-video', 'Equipos de sonido, audífonos, parlantes y video', cat_electronicos, 'fas fa-headphones', '#e67e22', 3),
    ('Televisores y Monitores', 'televisores-monitores', 'Televisores, monitores y pantallas', cat_electronicos, 'fas fa-tv', '#9b59b6', 4),
    ('Componentes PC', 'componentes-pc', 'Procesadores, memorias, tarjetas gráficas y componentes', cat_electronicos, 'fas fa-microchip', '#34495e', 5),
    ('Accesorios Electrónicos', 'accesorios-electronicos', 'Cables, cargadores, fundas y accesorios diversos', cat_electronicos, 'fas fa-plug', '#95a5a6', 6),
    ('Gaming', 'gaming', 'Consolas, videojuegos y accesorios gaming', cat_electronicos, 'fas fa-gamepad', '#e74c3c', 7),
    ('Electrodomésticos Pequeños', 'electrodomesticos-pequenos', 'Licuadoras, cafeteras, tostadoras y electrodomésticos menores', cat_electronicos, 'fas fa-blender', '#f39c12', 8);

    -- OFFICE SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Mobiliario de Oficina', 'mobiliario-oficina', 'Escritorios, sillas, archivadores y muebles de oficina', cat_oficina, 'fas fa-chair', '#2ecc71', 1),
    ('Suministros de Oficina', 'suministros-oficina', 'Papel, bolígrafos, carpetas y material de oficina', cat_oficina, 'fas fa-pen', '#27ae60', 2),
    ('Equipos de Oficina', 'equipos-oficina', 'Impresoras, escáneres, fotocopiadoras y equipos', cat_oficina, 'fas fa-print', '#16a085', 3),
    ('Organización', 'organizacion', 'Organizadores, bandejas, separadores y sistemas de archivo', cat_oficina, 'fas fa-folder-open', '#1e8449', 4),
    ('Presentación', 'presentacion', 'Proyectores, pizarras, marcadores y material de presentación', cat_oficina, 'fas fa-chalkboard-teacher', '#229954', 5);

    -- HOME SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Electrodomésticos Mayores', 'electrodomesticos-mayores', 'Neveras, lavadoras, estufas y electrodomésticos grandes', cat_hogar, 'fas fa-washing-machine', '#e74c3c', 1),
    ('Limpieza del Hogar', 'limpieza-hogar', 'Productos de limpieza, detergentes y utensilios', cat_hogar, 'fas fa-broom', '#c0392b', 2),
    ('Decoración', 'decoracion', 'Cuadros, plantas, velas y elementos decorativos', cat_hogar, 'fas fa-palette', '#a93226', 3),
    ('Cocina y Comedor', 'cocina-comedor', 'Utensilios de cocina, vajillas y accesorios culinarios', cat_hogar, 'fas fa-utensils', '#922b21', 4),
    ('Baño', 'bano', 'Productos para el baño, toallas y accesorios', cat_hogar, 'fas fa-bath', '#7b241c', 5),
    ('Textiles del Hogar', 'textiles-hogar', 'Sábanas, cortinas, cojines y textiles', cat_hogar, 'fas fa-bed', '#641e16', 6);

    -- SPORTS SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Fitness y Gimnasio', 'fitness-gimnasio', 'Equipos de ejercicio, pesas y accesorios de gimnasio', cat_deportes, 'fas fa-dumbbell', '#f39c12', 1),
    ('Deportes de Pelota', 'deportes-pelota', 'Fútbol, baloncesto, tenis, voleibol y deportes con pelota', cat_deportes, 'fas fa-basketball-ball', '#e67e22', 2),
    ('Deportes Acuáticos', 'deportes-acuaticos', 'Natación, surf, buceo y deportes en el agua', cat_deportes, 'fas fa-swimmer', '#d68910', 3),
    ('Ciclismo', 'ciclismo', 'Bicicletas, cascos, accesorios y equipos de ciclismo', cat_deportes, 'fas fa-bicycle', '#b7950b', 4),
    ('Deportes de Aventura', 'deportes-aventura', 'Camping, escalada, senderismo y deportes extremos', cat_deportes, 'fas fa-mountain', '#9a7d0a', 5),
    ('Ropa Deportiva', 'ropa-deportiva', 'Prendas deportivas, calzado deportivo y accesorios', cat_deportes, 'fas fa-running', '#7d6608', 6);

    -- HEALTH SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Medicamentos', 'medicamentos', 'Medicamentos de venta libre y productos farmacéuticos', cat_salud, 'fas fa-pills', '#9b59b6', 1),
    ('Equipos Médicos', 'equipos-medicos', 'Tensiómetros, termómetros y equipos de diagnóstico', cat_salud, 'fas fa-stethoscope', '#8e44ad', 2),
    ('Primeros Auxilios', 'primeros-auxilios', 'Botiquines, vendas, antisépticos y material de curación', cat_salud, 'fas fa-first-aid', '#7d3c98', 3),
    ('Suplementos', 'suplementos', 'Vitaminas, minerales y suplementos nutricionales', cat_salud, 'fas fa-capsules', '#6c3483', 4),
    ('Cuidado Dental', 'cuidado-dental', 'Cepillos, pasta dental y productos de higiene oral', cat_salud, 'fas fa-tooth', '#5b2c6f', 5),
    ('Ortopedia', 'ortopedia', 'Productos ortopédicos, sillas de ruedas y ayudas técnicas', cat_salud, 'fas fa-wheelchair', '#4a235a', 6);

    -- FOOD & BEVERAGES SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Alimentos Básicos', 'alimentos-basicos', 'Arroz, pasta, aceites y productos de primera necesidad', cat_alimentos, 'fas fa-bread-slice', '#27ae60', 1),
    ('Bebidas', 'bebidas', 'Refrescos, jugos, agua y bebidas alcohólicas', cat_alimentos, 'fas fa-wine-bottle', '#229954', 2),
    ('Lácteos', 'lacteos', 'Leche, quesos, yogurt y productos lácteos', cat_alimentos, 'fas fa-cheese', '#1e8449', 3),
    ('Carnes y Pescados', 'carnes-pescados', 'Carnes frescas, embutidos y productos del mar', cat_alimentos, 'fas fa-fish', '#196f3d', 4),
    ('Frutas y Verduras', 'frutas-verduras', 'Productos frescos, frutas y vegetales', cat_alimentos, 'fas fa-apple-alt', '#145a32', 5),
    ('Snacks y Dulces', 'snacks-dulces', 'Galletas, chocolates, dulces y aperitivos', cat_alimentos, 'fas fa-candy-cane', '#0e4b99', 6);

    -- CLOTHING SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Ropa Masculina', 'ropa-masculina', 'Prendas de vestir para hombres', cat_ropa, 'fas fa-male', '#8e44ad', 1),
    ('Ropa Femenina', 'ropa-femenina', 'Prendas de vestir para mujeres', cat_ropa, 'fas fa-female', '#7d3c98', 2),
    ('Ropa Infantil', 'ropa-infantil', 'Prendas de vestir para niños y bebés', cat_ropa, 'fas fa-baby', '#6c3483', 3),
    ('Calzado', 'calzado', 'Zapatos, botas, sandalias y calzado en general', cat_ropa, 'fas fa-shoe-prints', '#5b2c6f', 4),
    ('Accesorios de Moda', 'accesorios-moda', 'Bolsos, cinturones, joyas y accesorios', cat_ropa, 'fas fa-gem', '#4a235a', 5),
    ('Ropa Interior', 'ropa-interior', 'Ropa interior y prendas íntimas', cat_ropa, 'fas fa-tshirt', '#3b1f47', 6);

    -- CONSTRUCTION SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Herramientas Manuales', 'herramientas-manuales', 'Martillos, destornilladores, llaves y herramientas básicas', cat_construccion, 'fas fa-hammer', '#34495e', 1),
    ('Herramientas Eléctricas', 'herramientas-electricas', 'Taladros, sierras, pulidoras y herramientas eléctricas', cat_construccion, 'fas fa-tools', '#2c3e50', 2),
    ('Materiales de Construcción', 'materiales-construccion', 'Cemento, ladrillos, varillas y materiales básicos', cat_construccion, 'fas fa-hard-hat', '#273746', 3),
    ('Plomería', 'plomeria', 'Tuberías, grifos, accesorios y materiales de plomería', cat_construccion, 'fas fa-wrench', '#212f3c', 4),
    ('Electricidad', 'electricidad', 'Cables, interruptores, tomacorrientes y material eléctrico', cat_construccion, 'fas fa-bolt', '#1b2631', 5),
    ('Pintura y Acabados', 'pintura-acabados', 'Pinturas, brochas, rodillos y materiales de acabado', cat_construccion, 'fas fa-paint-roller', '#17202a', 6);

    -- AUTOMOTIVE SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Repuestos Motor', 'repuestos-motor', 'Filtros, aceites, bujías y repuestos del motor', cat_automotriz, 'fas fa-cog', '#e67e22', 1),
    ('Llantas y Rines', 'llantas-rines', 'Llantas, rines y accesorios para ruedas', cat_automotriz, 'fas fa-tire', '#d68910', 2),
    ('Accesorios Externos', 'accesorios-externos', 'Espejos, luces, parachoques y accesorios exteriores', cat_automotriz, 'fas fa-car-side', '#b7950b', 3),
    ('Accesorios Internos', 'accesorios-internos', 'Fundas, tapetes, sistemas de audio y accesorios internos', cat_automotriz, 'fas fa-car-seat', '#9a7d0a', 4),
    ('Herramientas Automotrices', 'herramientas-automotrices', 'Llaves, gatos, herramientas especializadas para autos', cat_automotriz, 'fas fa-wrench', '#7d6608', 5),
    ('Cuidado del Vehículo', 'cuidado-vehiculo', 'Ceras, champús, productos de limpieza automotriz', cat_automotriz, 'fas fa-spray-can', '#6e5a07', 6);

    -- BEAUTY SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Maquillaje', 'maquillaje', 'Bases, labiales, sombras y productos de maquillaje', cat_belleza, 'fas fa-palette', '#ff69b4', 1),
    ('Cuidado de la Piel', 'cuidado-piel', 'Cremas, limpiadores, protectores solares', cat_belleza, 'fas fa-hand-sparkles', '#e91e63', 2),
    ('Cuidado del Cabello', 'cuidado-cabello', 'Champús, acondicionadores, tratamientos capilares', cat_belleza, 'fas fa-cut', '#c2185b', 3),
    ('Fragancias', 'fragancias', 'Perfumes, colonias y productos aromáticos', cat_belleza, 'fas fa-spray-can', '#ad1457', 4),
    ('Uñas', 'unas', 'Esmaltes, limas, accesorios para manicure', cat_belleza, 'fas fa-hand-paper', '#880e4f', 5),
    ('Accesorios de Belleza', 'accesorios-belleza', 'Brochas, esponjas, espejos y herramientas', cat_belleza, 'fas fa-mirror', '#560027', 6);

    -- BOOKS & STATIONERY SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Libros Académicos', 'libros-academicos', 'Libros de texto, manuales y material educativo', cat_libros, 'fas fa-graduation-cap', '#795548', 1),
    ('Literatura', 'literatura', 'Novelas, cuentos, poesía y literatura general', cat_libros, 'fas fa-book-open', '#6d4c41', 2),
    ('Material Escolar', 'material-escolar', 'Cuadernos, lápices, reglas y útiles escolares', cat_libros, 'fas fa-pencil-alt', '#5d4037', 3),
    ('Papelería Corporativa', 'papeleria-corporativa', 'Papel membretado, tarjetas, material corporativo', cat_libros, 'fas fa-id-card', '#4e342e', 4),
    ('Arte y Manualidades', 'arte-manualidades', 'Pinturas, pinceles, materiales para manualidades', cat_libros, 'fas fa-paint-brush', '#3e2723', 5);

    -- PETS SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Alimento para Mascotas', 'alimento-mascotas', 'Concentrados, snacks y alimentos para perros y gatos', cat_mascotas, 'fas fa-bone', '#ff9800', 1),
    ('Accesorios para Perros', 'accesorios-perros', 'Collares, correas, juguetes y accesorios caninos', cat_mascotas, 'fas fa-dog', '#f57c00', 2),
    ('Accesorios para Gatos', 'accesorios-gatos', 'Areneras, rascadores, juguetes y accesorios felinos', cat_mascotas, 'fas fa-cat', '#ef6c00', 3),
    ('Higiene de Mascotas', 'higiene-mascotas', 'Champús, cepillos, productos de aseo', cat_mascotas, 'fas fa-shower', '#e65100', 4),
    ('Salud Animal', 'salud-animal', 'Vitaminas, medicamentos y productos veterinarios', cat_mascotas, 'fas fa-user-md', '#d84315', 5);

    -- GARDEN SUBCATEGORIES
    INSERT INTO categories (name, slug, description, parent_id, icon, color, sort_order) VALUES
    ('Plantas y Semillas', 'plantas-semillas', 'Plantas ornamentales, semillas y material vegetal', cat_jardin, 'fas fa-seedling', '#4caf50', 1),
    ('Herramientas de Jardín', 'herramientas-jardin', 'Palas, rastrillos, tijeras y herramientas de jardinería', cat_jardin, 'fas fa-tools', '#43a047', 2),
    ('Fertilizantes', 'fertilizantes', 'Abonos, fertilizantes y productos para el cuidado de plantas', cat_jardin, 'fas fa-leaf', '#388e3c', 3),
    ('Riego', 'riego', 'Mangueras, aspersores, sistemas de riego', cat_jardin, 'fas fa-tint', '#2e7d32', 4),
    ('Mobiliario Exterior', 'mobiliario-exterior', 'Mesas, sillas, sombrillas para exteriores', cat_jardin, 'fas fa-chair', '#1b5e20', 5),
    ('Iluminación Exterior', 'iluminacion-exterior', 'Lámparas solares, reflectores, iluminación de jardín', cat_jardin, 'fas fa-lightbulb', '#0d5302', 6);

END $$;

-- ==================== VERIFY CATEGORY STRUCTURE ====================

-- Show category hierarchy
WITH RECURSIVE category_tree AS (
    -- Base case: root categories
    SELECT 
        id, name, slug, parent_id, level, path,
        name as full_path,
        sort_order
    FROM categories 
    WHERE parent_id IS NULL AND is_active = true
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
        c.id, c.name, c.slug, c.parent_id, c.level, c.path,
        ct.full_path || ' > ' || c.name as full_path,
        c.sort_order
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
    WHERE c.is_active = true
)
SELECT 
    LPAD('', level * 2, ' ') || name as category_hierarchy,
    slug,
    level
FROM category_tree
ORDER BY full_path, sort_order;

-- Category count summary
SELECT 
    'Production categories structure created successfully' as status,
    COUNT(*) as total_categories,
    COUNT(CASE WHEN parent_id IS NULL THEN 1 END) as main_categories,
    COUNT(CASE WHEN parent_id IS NOT NULL THEN 1 END) as subcategories
FROM categories 
WHERE is_active = true;