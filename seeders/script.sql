--
-- PostgreSQL database seeder
-- Données d'exemple pour l'application
--

--
-- Données pour la table clients
--
INSERT INTO public.clients (id, nom, prenom, telephone, adresse, created_at, updated_at) VALUES
(14, 'NIANG', 'Die', '+221771234567', 'Dakar, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(15, 'DIOP', 'Fatou', '+221772345678', 'Thiès, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(16, 'FALL', 'Moussa', '+221773456789', 'Saint-Louis, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(17, 'BA', 'Aminata', '+221774567890', 'Kaolack, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(18, 'SARR', 'Ibrahima', '+221775678901', 'Ziguinchor, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(19, 'SOW', 'Ousmane', '+221776789012', 'Dakar, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(20, 'KANE', 'Khady', '+221777890123', 'Rufisque, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(21, 'DIALLO', 'Mamadou', '+221778901234', 'Kolda, Sénégal', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672');

--
-- Données pour la table tranches
--
INSERT INTO public.tranches (id, nom, min_montant, max_montant, prix_kw, ordre, created_at, updated_at) VALUES
(9, 'Tranche 1', 0.00, 5000.00, 98.0000, 1, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(10, 'Tranche 2', 5001.00, 15000.00, 105.0000, 2, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(11, 'Tranche 3', 15001.00, 30000.00, 115.0000, 3, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(12, 'Tranche 4', 30001.00, NULL, 125.0000, 4, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672');

--
-- Données pour la table compteurs
--
INSERT INTO public.compteurs (id, numero, client_id, actif, date_creation, created_at, updated_at) VALUES
(14, 'CPT123456', 14, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(15, 'CPT789012', 15, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(16, 'CPT345678', 16, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(17, 'CPT901234', 17, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(18, 'CPT567890', 18, false, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(19, 'CPT111222', 19, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(20, 'CPT333444', 20, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672'),
(21, 'CPT555666', 21, true, '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672', '2025-07-27 00:31:20.435672');

--
-- Données pour la table achats
--
INSERT INTO public.achats (id, reference, code_recharge, numero_compteur, montant, nbre_kwt, tranche, prix_kw, client_nom, date_achat, created_at, statut) VALUES
(1, 'WOY-20250727-6060', '1977-9016-5639-8453', 'CPT123456', 100.00, 1.02, 'Tranche 1', 98.00, 'Die NIANG', '2025-07-27 08:59:53', '2025-07-27 08:59:53.382653', 'success'),
(2, 'WOY-20250727-8173', '1135-2308-7747-1166', 'CPT123456', 1000.00, 10.20, 'Tranche 1', 98.00, 'Die NIANG', '2025-07-27 09:41:56', '2025-07-27 09:41:56.253276', 'success'),
(3, 'WOY-20250727-2782', '4903-2478-2420-2809', 'CPT123456', 100.00, 1.02, 'Tranche 1', 98.00, 'Die NIANG', '2025-07-27 10:30:41', '2025-07-27 10:30:41.577837', 'success'),
(4, 'WOY-20250727-2307', '6561-3565-4471-9012', 'CPT123456', 100.00, 1.02, 'Tranche 1', 98.00, 'Die NIANG', '2025-07-27 10:59:03', '2025-07-27 10:59:03.35908', 'success'),
(5, 'WOY-20250727-1549', '6289-3771-5554-1525', 'CPT123456', 100.00, 1.02, 'Tranche 1', 98.00, 'Die NIANG', '2025-07-27 10:59:45', '2025-07-27 10:59:45.91649', 'success');

--
-- Données pour la table logs_achats
--
INSERT INTO public.logs_achats (id, date_heure, localisation, adresse_ip, statut, numero_compteur, code_recharge, nbre_kwt, message_erreur, created_at) VALUES
(1, '2025-07-27 08:49:19', 'Dakar, Sénégal', '172.19.0.1', 'Échec', 'CPT123456', NULL, NULL, 'SQLSTATE[42P01]: Undefined table: 7 ERROR:  relation "achats" does not exist\nLINE 1: INSERT INTO achats (reference, code_recharge, numero_compteu...\n                    ^', '2025-07-27 08:49:19.239885'),
(2, '2025-07-27 08:56:25', 'Dakar, Sénégal', '172.19.0.1', 'Échec', 'CPT123456', NULL, NULL, 'SQLSTATE[42P01]: Undefined table: 7 ERROR:  relation "achats" does not exist\nLINE 1: INSERT INTO achats (reference, code_recharge, numero_compteu...\n                    ^', '2025-07-27 08:56:25.804369'),
(3, '2025-07-27 08:58:22', 'Dakar, Sénégal', '172.19.0.1', 'Échec', 'CPT123456', NULL, NULL, 'SQLSTATE[42703]: Undefined column: 7 ERROR:  column "statut" of relation "achats" does not exist\nLINE 2: ...          nbre_kwt, tranche, prix_kw, date_achat, statut, cl...\n                                                             ^', '2025-07-27 08:58:22.619359'),
(4, '2025-07-27 08:59:53', 'Dakar, Sénégal', '172.19.0.1', 'Success', 'CPT123456', '1977-9016-5639-8453', 1.02, NULL, '2025-07-27 08:59:53.385488'),
(5, '2025-07-27 09:41:56', 'Dakar, Sénégal', '172.19.0.1', 'Success', 'CPT123456', '1135-2308-7747-1166', 10.20, NULL, '2025-07-27 09:41:56.254475'),
(6, '2025-07-27 10:30:41', 'Dakar, Sénégal', '172.19.0.1', 'Success', 'CPT123456', '4903-2478-2420-2809', 1.02, NULL, '2025-07-27 10:30:41.585127'),
(7, '2025-07-27 10:59:03', 'Dakar, Sénégal', '172.19.0.1', 'Success', 'CPT123456', '6561-3565-4471-9012', 1.02, NULL, '2025-07-27 10:59:03.360458'),
(8, '2025-07-27 10:59:45', 'Dakar, Sénégal', '172.19.0.1', 'Success', 'CPT123456', '6289-3771-5554-1525', 1.02, NULL, '2025-07-27 10:59:45.920016');

--
-- Mise à jour des séquences pour éviter les conflits d'ID
--
SELECT pg_catalog.setval('public.achats_id_seq', 5, true);
SELECT pg_catalog.setval('public.clients_id_seq', 21, true);
SELECT pg_catalog.setval('public.compteurs_id_seq', 21, true);
SELECT pg_catalog.setval('public.logs_achats_id_seq', 8, true);
SELECT pg_catalog.setval('public.tranches_id_seq', 12, true);