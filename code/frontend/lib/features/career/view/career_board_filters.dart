part of 'career_board_page.dart';

extension _CareerBoardFilters on _CareerBoardPageState {
  Widget _header(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 14,
      spacing: 16,
      children: [
        SizedBox(
          width: constraints.maxWidth > 460
              ? constraints.maxWidth - 210
              : constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Career board', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                _student
                    ? 'Explore internships and jobs shared by your alumni community.'
                    : 'Explore alumni opportunities, share a role and manage your own posts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_alumni)
          FilledButton.icon(
            onPressed: _createPost,
            icon: const Icon(Icons.add),
            label: const Text('Post an opportunity'),
          ),
      ],
    ),
  );

  Widget _filters(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _employmentType == null,
            onSelected: (_) => _setEmployment(null),
          ),
          for (final type in CareerEmploymentType.values)
            ChoiceChip(
              label: Text(type.label),
              selected: _employmentType == type,
              onSelected: (_) => _setEmployment(type),
            ),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final fields = [
            SizedBox(
              width: wide ? 210 : constraints.maxWidth,
              child: TextField(
                controller: _location,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_outlined),
                  counterText: '',
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: wide ? 210 : constraints.maxWidth,
              child: TextField(
                controller: _skill,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Skill',
                  prefixIcon: Icon(Icons.sell_outlined),
                  counterText: '',
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: wide ? 170 : constraints.maxWidth,
              child: DropdownButtonFormField<CareerWorkMode?>(
                isExpanded: true,
                initialValue: _workMode,
                decoration: const InputDecoration(labelText: 'Work mode'),
                items: [
                  const DropdownMenuItem<CareerWorkMode?>(
                    value: null,
                    child: Text('Any mode'),
                  ),
                  for (final mode in CareerWorkMode.values)
                    DropdownMenuItem<CareerWorkMode?>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                ],
                onChanged: _setWorkMode,
              ),
            ),
            SizedBox(
              width: wide ? 190 : constraints.maxWidth,
              child: DropdownButtonFormField<CareerSort>(
                isExpanded: true,
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(
                    value: CareerSort.newest,
                    child: Text('Most recent'),
                  ),
                  DropdownMenuItem(
                    value: CareerSort.deadline,
                    child: Text('Closing soon'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _update(() {
                    _sort = value;
                    _queryRevision++;
                  });
                  unawaited(_load());
                },
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _loading ? null : _applyFilters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Apply filters'),
            ),
          ];
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: fields,
          );
        },
      ),
    ],
  );
}
