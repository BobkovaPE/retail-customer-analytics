"""Execute the notebooks' ordinary Python cells and retain real outputs."""
from contextlib import redirect_stdout, redirect_stderr
from io import StringIO
from pathlib import Path
import argparse
import base64
import json
import os
import traceback


def execute_notebook(path):
    notebook = json.loads(path.read_text(encoding='utf-8'))
    scope = {'__name__': '__main__'}
    count = 0
    last_figure = None
    for index, cell in enumerate(notebook['cells']):
        if cell['cell_type'] != 'code':
            continue
        count += 1
        source = cell['source']
        if isinstance(source, list):
            source = ''.join(source)
        stdout, stderr = StringIO(), StringIO()
        try:
            with redirect_stdout(stdout), redirect_stderr(stderr):
                exec(compile(source, f'{path.name}:cell-{index}', 'exec'), scope)
        except Exception:
            print(stdout.getvalue(), stderr.getvalue())
            traceback.print_exc()
            raise
        outputs = []
        for name, value in [('stdout', stdout.getvalue()), ('stderr', stderr.getvalue())]:
            if value:
                outputs.append({'output_type': 'stream', 'name': name, 'text': value})
        # The analytics notebook saves each chart in a new PNG before returning.
        figure = scope.get('latest_figure')
        if figure is not None and figure != last_figure:
            outputs.append({'output_type': 'display_data', 'metadata': {}, 'data': {
                'image/png': base64.b64encode(figure.read_bytes()).decode(),
                'text/plain': 'Figure produced by this cell'}})
            last_figure = figure
        cell['execution_count'], cell['outputs'] = count, outputs
        print(f'  Cell {count}: OK', flush=True)
        if stderr.getvalue():
            print(stderr.getvalue(), flush=True)
    # Only replace notebook outputs after all cells have completed successfully.
    # Writing in place preserves identity metadata of existing local files.
    path.write_text(json.dumps(notebook, ensure_ascii=False, indent=1)+'\n', encoding='utf-8')
    print(f'Completed {path.name}: {count} code cells', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--analysis-only', action='store_true',
                        help='Use the existing SQLite database; skip preparation.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    names = ['01_data_preparation.ipynb', '02_customer_analytics.ipynb',
             '03_experiment_design.ipynb']
    if args.analysis_only:
        names = names[1:]
    previous_directory = Path.cwd()
    previous_backend = os.environ.get('MPLBACKEND')
    try:
        os.chdir(root)
        os.environ['MPLBACKEND'] = 'Agg'
        for name in names:
            print(f'Running {name} ...', flush=True)
            execute_notebook(root / 'notebooks' / name)
    finally:
        os.chdir(previous_directory)
        if previous_backend is None:
            os.environ.pop('MPLBACKEND', None)
        else:
            os.environ['MPLBACKEND'] = previous_backend
    print('Complete. Tables, figures and notebook outputs have been updated.')


if __name__ == '__main__':
    main()
