part of '../project_finder_page.dart';

extension _ProjectFilterBar on _ProjectFinderPageState {
  Widget _filterBar() => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 780;
          final filters = <Widget>[
            TextField(
              controller: _skillFilter,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilters(),
              decoration: const InputDecoration(
                labelText: 'Skill',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            DropdownButtonFormField<int?>(
              key: ValueKey('department-${_controller.filters.departmentId}'),
              initialValue: _controller.filters.departmentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Department',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All departments'),
                ),
                for (final department in _departments)
                  DropdownMenuItem<int?>(
                    value: department.id,
                    child: Text(
                      department.code.isEmpty
                          ? department.name
                          : '${department.code} · ${department.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(
                  departmentId: value,
                  clearDepartment: value == null,
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('availability-${_controller.filters.availability}'),
              initialValue: _controller.filters.availability,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Availability',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Available and full')),
                DropdownMenuItem(value: 'AVAILABLE', child: Text('Has room')),
                DropdownMenuItem(value: 'FULL', child: Text('Full teams')),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(availability: value ?? ''),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('sort-${_controller.filters.sort}'),
              initialValue: _controller.filters.sort,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sort',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'CREATED_DESC', child: Text('Newest')),
                DropdownMenuItem(
                  value: 'DEADLINE_ASC',
                  child: Text('Deadline soonest'),
                ),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(sort: value ?? 'CREATED_DESC'),
              ),
            ),
            FilledButton.icon(
              onPressed: _controller.openLoading ? null : _applyFilters,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filter'),
            ),
            IconButton(
              onPressed: () {
                _skillFilter.clear();
                _controller.clearFilters();
              },
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Clear filters',
            ),
          ];
          if (narrow) {
            return Column(
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(width: double.infinity, child: filter),
                  ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: filters[0]),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: filters[1]),
              const SizedBox(width: 10),
              Expanded(child: filters[2]),
              const SizedBox(width: 10),
              Expanded(child: filters[3]),
              const SizedBox(width: 8),
              filters[4],
              filters[5],
            ],
          );
        },
      ),
    ),
  );

  void _applyFilters() {
    _controller.updateFilters(
      _controller.filters.copyWith(skill: _skillFilter.text),
    );
  }
}
