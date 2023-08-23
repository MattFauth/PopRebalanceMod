from django.shortcuts import render
from django.http import JsonResponse
import os
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
def count_population(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        saved_files = save_files(uploaded_files)
        grand_total_size = 0
        per_file_count = {}
        for filepath in saved_files:
            total_size = parse_file(filepath)
            per_file_count[os.path.basename(filepath)] = total_size
            grand_total_size += total_size
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
    with open(filepath, 'w') as file:
        file.writelines(updated_lines)

# Django view function to handle population scaling
def scale_population(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        saved_files = save_files(uploaded_files)
        # This should be replaced with real scaling factor, passed from the client
        scaling_factor = float(request.POST.get('scaling_factor', 1))
        for filepath in saved_files:
            scale_file_population(filepath, scaling_factor)
        return JsonResponse({'message': 'Population scaled'})