# Pasos para ejecutar:

1. Codificar videos:
```
bash
./encode_video.sh ./mobile_cif

```
2. Generar trazas:
```
bash
./generate_traces.sh ./videos
```

3. Correr las simulaciones:
```
bash
./run_ns3_simulations.sh ./videos 85
```

4. Reconstruir Video recibido:
```
bash
./reconstruct_videos.sh ./videos 
```

5. Calcular PSNR:
```
bash
./calculate_psnr.sh
```