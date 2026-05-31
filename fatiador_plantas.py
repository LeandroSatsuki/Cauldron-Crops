from PIL import Image
import os

# Caminhos das imagens de origem
assets_dir = r"e:\Cauldron Crops\cauldron-crops\Assets"
crops1_path = os.path.join(assets_dir, "crops_1.png")
crops2_path = os.path.join(assets_dir, "crops_2.png")

# Configuração de mapeamento
crops1_cols = {0: "milho", 1: "tomate", 2: "abobora", 3: "rabanete"}
crops2_cols = {0: "trigo", 1: "feijao", 2: "cebola", 3: "cenoura"}
stages = {0: "broto", 1: "crescendo", 2: "maduro"}

def fatiar_image(image_path, mapping):
    img = Image.open(image_path)
    width, height = img.size
    cell_w = width // 4
    cell_h = height // 3

    for row in range(3):
        stage_name = stages[row]
        for col in range(4):
            plant_name = mapping[col]
            left = col * cell_w
            top = row * cell_h
            right = left + cell_w
            bottom = top + cell_h
            
            # Recorta a célula
            cell = img.crop((left, top, right, bottom))
            
            # Nome do arquivo final
            dest_name = f"{plant_name}_{stage_name}.png"
            dest_path = os.path.join(assets_dir, dest_name)
            
            cell.save(dest_path, "PNG")
            print(f"Salvo: {dest_name}")

if __name__ == "__main__":
    print("Iniciando fatiamento das crops...")
    if os.path.exists(crops1_path):
        fatiar_image(crops1_path, crops1_cols)
    else:
        print(f"Erro: Arquivo {crops1_path} não encontrado!")
        
    if os.path.exists(crops2_path):
        fatiar_image(crops2_path, crops2_cols)
    else:
        print(f"Erro: Arquivo {crops2_path} não encontrado!")
    print("Fatiamento concluído com sucesso!")
