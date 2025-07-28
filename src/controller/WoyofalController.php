<?php

namespace App\Controller;

use App\Service\WoyofalService;

class WoyofalController 
{
    private WoyofalService $woyofalService;
    
    public function __construct()
    {
        $this->woyofalService = new WoyofalService();
    }

    public function acheter(): void
    {
        try {
            error_log("========= DEBUT FONCTION ACHETER =========");
            
            error_log(message: "Method: " . $_SERVER['REQUEST_METHOD']);
            error_log("Content-Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'non défini'));
            error_log("Query String: " . ($_SERVER['QUERY_STRING'] ?? 'vide'));
            error_log("Request URI: " . ($_SERVER['REQUEST_URI'] ?? 'non défini'));
            error_log("GET params: " . json_encode($_GET));
            error_log("POST params: " . json_encode($_POST));
            
            $rawInput = file_get_contents('php://input');
            error_log("Raw input length: " . strlen($rawInput));
            error_log("Raw input content: '" . $rawInput . "'");
            error_log("Raw input hex: " . bin2hex($rawInput));
            
            $input = null;
            
          
            if (!empty($_GET)) {
                $input = $_GET;
                error_log(" Utilisation des données GET: " . json_encode($input));
            }
            
            elseif (!empty($_POST)) {
                $input = $_POST;
                error_log(" Utilisation des données POST: " . json_encode($input));
            }
            
            elseif (!empty($rawInput)) {
                $jsonInput = json_decode($rawInput, true);
                if ($jsonInput !== null && json_last_error() === JSON_ERROR_NONE) {
                    $input = $jsonInput;
                    error_log(" Utilisation des données JSON: " . json_encode($input));
                } else {
                    error_log(" Erreur JSON: " . json_last_error_msg());
                    if (strpos($rawInput, '=') !== false) {
                        parse_str($rawInput, $parsedInput);
                        if (!empty($parsedInput)) {
                            $input = $parsedInput;
                            error_log("Utilisation query string: " . json_encode($input));
                        }
                    }
                }
            }
            
            // 4. Debug final de ce qu'on a récupéré
            error_log("Input final complet: " . json_encode($input));
            error_log("Input est null? " . ($input === null ? 'OUI' : 'NON'));
            error_log("Input est vide? " . (empty($input) ? 'OUI' : 'NON'));
            
            // 5. Si vraiment aucune donnée
            if (!$input || empty($input)) {
                error_log("AUCUNE DONNÉE FINALE");
                
                // Réponse de debug complète
                $debugInfo = [
                    'message' => 'Aucune donnée reçue',
                    'debug' => [
                        'method' => $_SERVER['REQUEST_METHOD'],
                        'content_type' => $_SERVER['CONTENT_TYPE'] ?? null,
                        'query_string' => $_SERVER['QUERY_STRING'] ?? null,
                        'get_count' => count($_GET),
                        'post_count' => count($_POST),
                        'raw_length' => strlen($rawInput),
                        'raw_sample' => substr($rawInput, 0, 100)
                    ]
                ];
                
                $this->sendErrorResponse(json_encode($debugInfo, JSON_PRETTY_PRINT), 400);
                return;
            }
            
            // 4. Valider les champs requis
            if (!isset($input['numero_compteur']) || empty($input['numero_compteur'])) {
                error_log(" numero_compteur manquant dans: " . json_encode($input));
                $this->sendErrorResponse('Le numéro de compteur est requis', 400);
                return;
            }
            
            if (!isset($input['montant']) || !is_numeric($input['montant'])) {
                error_log("montant invalide: " . ($input['montant'] ?? 'non défini'));
                $this->sendErrorResponse('Le montant est requis et doit être numérique', 400);
                return;
            }
            
            $numero_compteur = trim($input['numero_compteur']);
            $montant = (float) $input['montant'];

            error_log(" Données validées - Compteur: $numero_compteur, Montant: $montant");

            error_log("Appel du service effectuerAchat...");
            $result = $this->woyofalService->effectuerAchat($numero_compteur, $montant);
            error_log("Résultat du service: " . json_encode($result));
            
            $this->sendResponse($result);
            
        } catch (\Exception $e) {
            error_log("Erreur dans acheter(): " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            $this->sendErrorResponse('Erreur lors de l\'achat: ' . $e->getMessage(), 500);
        }
    }
    
    public function verifierCompteur(string $numero): void
    {
        try {
            $numero = trim($numero);
            
            if (empty($numero)) {
                $this->sendErrorResponse('Numéro de compteur requis', 400);
                return;
            }
            
            $result = $this->woyofalService->verifierCompteur($numero);
            $this->sendResponse($result);
            
        } catch (\Exception $e) {
            error_log("Erreur dans verifierCompteur(): " . $e->getMessage());
            $this->sendErrorResponse('Erreur lors de la vérification: ' . $e->getMessage(), 500);
        }
    }
    
    private function sendResponse(array $data): void
    {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($data['code']);
        
        echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }
    
    private function sendErrorResponse(string $message, int $code = 400): void
    {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($code);
        
        echo json_encode([
            'data' => null,
            'statut' => 'error',
            'code' => $code,
            'message' => $message
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }
}