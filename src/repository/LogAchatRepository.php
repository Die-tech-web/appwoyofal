<?php

namespace App\Repository;

use App\Entity\LogAchat;
use DevNoKage\Database;

class LogAchatRepository
{
    private \PDO $connection;
    
    public function __construct()
    {
        $this->connection = Database::getInstance(
            'pgsql',
            'db',
            5432,
            'appwoyofal',
            'postgres',
            'madie'
        )->getConnexion();
    }
    
    public function save(LogAchat $log): LogAchat
    {
        try {
            error_log("💾 LogAchatRepository::save - Début");
            
            $sql = "INSERT INTO logs_achats (date_heure, localisation, adresse_ip, statut, 
                    numero_compteur, code_recharge, nbre_kwt, message_erreur) 
                    VALUES (:date_heure, :localisation, :adresse_ip, :statut, 
                    :numero_compteur, :code_recharge, :nbre_kwt, :message_erreur) RETURNING id";
            
            error_log("📝 SQL: " . $sql);
            
            $stmt = $this->connection->prepare($sql);
            
            $dateHeure = $log->getDateHeure() ? 
                $log->getDateHeure()->format('Y-m-d H:i:s') : 
                date('Y-m-d H:i:s');
            
            error_log(" Date/heure: " . $dateHeure);
            error_log(" Localisation: " . $log->getLocalisation());
            error_log(" IP: " . $log->getAdresseIp());
            error_log(" Statut: " . $log->getStatut());
            error_log(" Compteur: " . $log->getNumeroCompteur());
            error_log(" Code recharge: " . ($log->getCodeRecharge() ?? 'null'));
            error_log(" kWh: " . ($log->getNbreKwt() ?? 'null'));
            error_log(" Message erreur: " . ($log->getMessageErreur() ?? 'null'));
            
            $stmt->bindValue(':date_heure', $dateHeure);
            $stmt->bindValue(':localisation', $log->getLocalisation());
            $stmt->bindValue(':adresse_ip', $log->getAdresseIp());
            $stmt->bindValue(':statut', $log->getStatut());
            $stmt->bindValue(':numero_compteur', $log->getNumeroCompteur());
            
            $stmt->bindValue(':code_recharge', $log->getCodeRecharge(), 
                $log->getCodeRecharge() === null ? \PDO::PARAM_NULL : \PDO::PARAM_STR);
            $stmt->bindValue(':nbre_kwt', $log->getNbreKwt(), 
                $log->getNbreKwt() === null ? \PDO::PARAM_NULL : \PDO::PARAM_STR);
            $stmt->bindValue(':message_erreur', $log->getMessageErreur(), 
                $log->getMessageErreur() === null ? \PDO::PARAM_NULL : \PDO::PARAM_STR);
            
            error_log("🚀 Exécution de la requête...");
            $stmt->execute();
            
            $id = $stmt->fetchColumn();
            error_log("✅ Log sauvé avec ID: " . $id);
            
            $log->setId($id);
            
            if (!$log->getDateHeure()) {
                $log->setDateHeure(new \DateTime());
            }
            
            return $log;
            
        } catch (\Exception $e) {
            error_log("❌ Erreur dans LogAchatRepository::save: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            throw $e;
        }
    }
}