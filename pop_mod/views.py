from django.shortcuts import render
from django.http import JsonResponse
import os
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage

# Utility function to save files and return their paths
def save_files(files):
    fs = FileSystemStorage()
    saved_files = []
    for uploaded_file in files:
        filename = fs.save(uploaded_file.name, uploaded_file)
        saved_files.append(fs.path(filename))
    return saved_files

# Utility function to parse and count population from a file
def parse_file(filepath):
    total_size = 0
    with open(filepath, 'r') as file:
        lines = file.readlines()
    for line in lines:
        if 'size = ' in line:
            size_str = line.split('=')[1].split('#')[0].strip()
            try:
                size_value = int(size_str)
                total_size += size_value
            except ValueError as e:
                print(f"Skipping line due to error: {e}. Line content: {line.strip()}")
    return total_size

# Endpoint for file uploads
@csrf_exempt
def upload_files(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        # Validate file type and size
        for uploaded_file in uploaded_files:
            if not uploaded_file.name.endswith('.txt'):
                return JsonResponse({'error': 'Invalid file type. Only .txt files are allowed.'})
            if uploaded_file.size > 61440:  # 60 * 1024
                return JsonResponse({'error': 'File size exceeds the limit of 60 KB.'})
        # Save the files
        save_files(uploaded_files)
        return JsonResponse({'message': 'Files uploaded successfully'})


# Endpoint for counting total population
@csrf_exempt
def count_population(request):
    print('Function is called, here is the request: ', request)
    if request.method == 'POST':
        print('inside the if: ')
        # Logo após pegar os arquivos carregados:
        uploaded_files = request.FILES.getlist('files')
        print(f'Number of uploaded files: {len(uploaded_files)}')
        # Após salvar os arquivos, para verificar os caminhos dos arquivos salvos:
        saved_files = save_files(uploaded_files)
        print(f'Saved files: {saved_files}')
        grand_total_size = 0
        per_file_count = {}
        for filepath in saved_files:
            total_size = parse_file(filepath)
            print(f"Total size for {os.path.basename(filepath)}: {total_size}")  # Para registrar o tamanho total de cada arquivo
            per_file_count[os.path.basename(filepath)] = total_size
            grand_total_size += total_size
            os.remove(filepath)
        # Antes de retornar a resposta, para verificar a contagem total e por arquivo:
        print(f'Total population: {grand_total_size}')
        print(f'Per file count: {per_file_count}')
        return JsonResponse({
            'total_population': grand_total_size,
            'per_file_count': per_file_count
        })


# Utility function to scale population in a file
def scale_file_population(filepath, scaling_factor):
    updated_lines = []
    with open(filepath, 'r') as file:
        lines = file.readlines()
    for line in lines:
        if 'size = ' in line:
            original_size_str = line.split('=')[1].split('#')[0].strip()
            original_size = int(original_size_str)
            scaled_size = int(original_size * scaling_factor)
            updated_line = f"size = {scaled_size}\n"
            updated_lines.append(updated_line)
        else:
            updated_lines.append(line)
    # Convert the updated lines to bytes
    updated_content = ''.join(updated_lines)
    return updated_content.encode()


# Django view function to handle population scaling
@csrf_exempt
def scale_population(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        saved_files = save_files(uploaded_files)
        scaling_factor = float(request.POST.get('scaling_factor', 1))
        processed_files_data = {}
        for filepath in saved_files:
            filename = os.path.basename(filepath)
            processed_file_data = scale_file_population(filepath, scaling_factor)
            # Convert bytes to string and store in the dictionary
            processed_files_data[filename] = processed_file_data.decode('utf-8')
            os.remove(filepath)  # Don't forget to remove the file after processing
        return JsonResponse(processed_files_data)