# modules/profile_manager.py

"""
Gestor de perfiles de configuración
"""

import json
from pathlib import Path


class ProfileManager:
    def __init__(self, config_dir="config"):
        """Inicializar el gestor de perfiles"""
        self.config_dir = Path(config_dir)
        self.config_file = self.config_dir / "videoconf_profiles.json"
        self.profiles = {}
        self._ensure_config_dir()
        self._load_profiles()
    
    def _ensure_config_dir(self):
        """Asegurar que el directorio de configuración existe"""
        if not self.config_dir.exists():
            self.config_dir.mkdir(parents=True, exist_ok=True)
    
    def _get_default_profiles(self):
        """Obtener perfiles por defecto"""
        return {
            "cercano": {
                "width": 1920,
                "height": 1080,
                "video_bitrate": 8000,
                "audio_bitrate": 128,
                "muestras": 48000
            },
            "medio": {

                "width": 1280,
                "height": 720,
                "video_bitrate": 4000,
                "audio_bitrate": 96,
                "muestras": 44100
            },
            "lejano": {

                "width": 854,
                "height": 480,
                "video_bitrate": 1500,
                "audio_bitrate": 64,
                "muestras": 32000
            }
        }
    
    def _load_profiles(self):
        """Cargar perfiles desde archivo JSON"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    self.profiles = json.load(f)
                print(f"Perfiles cargados desde {self.config_file}")
            except Exception as e:
                print(f"Error al cargar perfiles: {e}")
                self.profiles = self._get_default_profiles()
                self._save_profiles()
        else:
            print("Creando perfiles por defecto...")
            self.profiles = self._get_default_profiles()
            self._save_profiles()
    
    def _save_profiles(self):
        """Guardar todos los perfiles al archivo JSON"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.profiles, f, indent=2)
            return True
        except Exception as e:
            print(f"Error al guardar perfiles: {e}")
            return False
    
    def load_profile(self, profile_name):
        """
        Cargar un perfil específico
        
        Args:
            profile_name: Nombre del perfil a cargar
            
        Returns:
            dict: Parámetros del perfil o None si no existe
        """
        if profile_name in self.profiles:
            return self.profiles[profile_name].copy()
        else:
            print(f"Perfil '{profile_name}' no encontrado")
            return None
    
    def save_profile(self, profile_name, params):
        """
        Guardar un perfil
        
        Args:
            profile_name: Nombre del perfil
            params: Diccionario con los parámetros
            
        Returns:
            bool: True si se guardó correctamente
        """
        self.profiles[profile_name] = params
        return self._save_profiles()
    
    def get_profile_names(self):
        """Obtener lista de nombres de perfiles"""
        return list(self.profiles.keys())
    
    def delete_profile(self, profile_name):
        """
        Eliminar un perfil
        
        Args:
            profile_name: Nombre del perfil a eliminar
            
        Returns:
            bool: True si se eliminó correctamente
        """
        if profile_name in self.profiles:
            del self.profiles[profile_name]
            return self._save_profiles()
        return False
    
    def create_profile(self, profile_name, base_profile="medio"):
        """
        Crear un nuevo perfil basado en uno existente
        
        Args:
            profile_name: Nombre del nuevo perfil
            base_profile: Perfil base para copiar parámetros
            
        Returns:
            bool: True si se creó correctamente
        """
        if base_profile in self.profiles:
            self.profiles[profile_name] = self.profiles[base_profile].copy()
            return self._save_profiles()
        return False