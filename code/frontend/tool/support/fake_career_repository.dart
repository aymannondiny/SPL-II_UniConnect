import 'package:uniconnect/features/career/data/career_repository.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

/// Visual-only career listings. This repository is imported by tool/preview.dart,
/// never by the production application entry point.
class FakeCareerRepository implements CareerRepository {
  FakeCareerRepository() {
    _posts = [
      _post(
        101,
        'Junior Flutter developer',
        'Orbit Labs',
        CareerEmploymentType.internship,
        CareerWorkMode.hybrid,
        'Dhaka',
        '30 Oct',
        'Help build mobile experiences with an experienced product team.',
        const ['Flutter', 'Dart', 'REST APIs'],
      ),
      _post(
        102,
        'Backend engineer (Java)',
        'Meridian Systems',
        CareerEmploymentType.fullTime,
        CareerWorkMode.onsite,
        'Dhaka',
        '12 Nov',
        'Join a collaborative engineering group working on campus products.',
        const ['Java', 'Spring Boot', 'PostgreSQL'],
      ),
      _post(
        103,
        'Data analyst',
        'Northstar Analytics',
        CareerEmploymentType.partTime,
        CareerWorkMode.remote,
        'Remote',
        '18 Nov',
        'Turn research and product data into clear recommendations.',
        const ['SQL', 'Python', 'Communication'],
      ),
      _post(
        104,
        'Embedded systems intern',
        'Kestrel Devices',
        CareerEmploymentType.internship,
        CareerWorkMode.onsite,
        'Gazipur',
        '5 Dec',
        'Work with the firmware team on connected hardware prototypes.',
        const ['C', 'Embedded Linux', 'Electronics'],
      ),
    ];
    _saved.add(
      SavedCareerPost(
        id: 1102,
        note: 'Ask Amina about the team’s current projects.',
        savedAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        post: _posts[1],
      ),
    );
  }

  late List<CareerPost> _posts;
  final List<SavedCareerPost> _saved = [];

  CareerPost _post(
    int id,
    String title,
    String company,
    CareerEmploymentType employment,
    CareerWorkMode mode,
    String location,
    String deadline,
    String description,
    List<String> skillNames,
  ) {
    final now = DateTime.now();
    final parts = deadline.split(' ');
    final parsedDay = int.tryParse(parts.first) ?? 30;
    const monthNumbers = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parsedMonth = monthNumbers[parts.last] ?? now.month;
    final today = DateTime(now.year, now.month, now.day);
    var dueDate = DateTime(now.year, parsedMonth, parsedDay);
    if (dueDate.isBefore(today)) {
      dueDate = DateTime(now.year + 1, parsedMonth, parsedDay);
    }
    return CareerPost(
      id: id,
      title: title,
      companyName: company,
      description: description,
      qualifications: 'A portfolio or relevant project experience is welcome.',
      location: location,
      employmentType: employment,
      workMode: mode,
      salaryRange: id == 102 ? 'Competitive' : null,
      applicationUrl: 'https://example.com/careers/$id',
      applicationEmail: null,
      applicationDeadline: dueDate,
      status: CareerAvailability.published,
      saved: _saved.any((item) => item.post.id == id),
      canApply: true,
      applicationChannels: const {CareerApplicationChannel.url},
      skills: [
        for (var i = 0; i < skillNames.length; i++)
          CareerSkill(id: id * 10 + i, name: skillNames[i], required: i < 2),
      ],
      authorUserId: id == 101 ? 1 : 7,
      authorDisplayName: 'Amina Rahman',
      postedAt: now.subtract(Duration(days: id % 4 + 1)),
      updatedAt: now,
      closedAt: null,
    );
  }

  @override
  Future<CareerPage<CareerPost>> browse({
    required int page,
    CareerEmploymentType? employmentType,
    CareerWorkMode? workMode,
    String? location,
    String? skill,
    required CareerSort sort,
  }) async {
    final filtered = _posts.where((post) {
      if (employmentType != null && post.employmentType != employmentType) {
        return false;
      }
      if (workMode != null && post.workMode != workMode) return false;
      if (location != null &&
          !post.location!.toLowerCase().contains(location.toLowerCase())) {
        return false;
      }
      if (skill != null &&
          !post.skills.any(
            (value) => value.name.toLowerCase().contains(skill.toLowerCase()),
          )) {
        return false;
      }
      return true;
    }).toList();
    return CareerPage(
      items: [for (final post in filtered) _withSavedState(post)],
      page: page,
      size: 20,
      totalElements: filtered.length,
    );
  }

  @override
  Future<CareerPage<CareerPost>> mine({required int page}) async => CareerPage(
    items: _posts.where((post) => post.authorUserId == 1).toList(),
    page: page,
    size: 20,
    totalElements: _posts.where((post) => post.authorUserId == 1).length,
  );

  @override
  Future<CareerPage<SavedCareerPost>> saved({required int page}) async =>
      CareerPage(
        items: [..._saved],
        page: page,
        size: 20,
        totalElements: _saved.length,
      );

  @override
  Future<CareerPost> detail(int postId) async =>
      _withSavedState(_posts.firstWhere((post) => post.id == postId));

  CareerPost _withSavedState(CareerPost post) => CareerPost(
    id: post.id,
    title: post.title,
    companyName: post.companyName,
    description: post.description,
    qualifications: post.qualifications,
    location: post.location,
    employmentType: post.employmentType,
    workMode: post.workMode,
    salaryRange: post.salaryRange,
    applicationUrl: post.applicationUrl,
    applicationEmail: post.applicationEmail,
    applicationDeadline: post.applicationDeadline,
    status: post.status,
    saved: _saved.any((item) => item.post.id == post.id),
    canApply: post.canApply,
    applicationChannels: post.applicationChannels,
    skills: post.skills,
    authorUserId: post.authorUserId,
    authorDisplayName: post.authorDisplayName,
    postedAt: post.postedAt,
    updatedAt: post.updatedAt,
    closedAt: post.closedAt,
  );

  @override
  Future<SavedCareerPost> save(int postId, {String? note}) async {
    final saved = SavedCareerPost(
      id: postId + 1000,
      note: note,
      savedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      post: _withSavedState(_posts.firstWhere((post) => post.id == postId)),
    );
    _saved.add(saved);
    return saved;
  }

  @override
  Future<void> unsave(int postId) async =>
      _saved.removeWhere((item) => item.post.id == postId);

  @override
  Future<SavedCareerPost> updateNote(int savedJobId, String? note) async {
    final index = _saved.indexWhere((item) => item.id == savedJobId);
    final old = _saved[index];
    final updated = SavedCareerPost(
      id: old.id,
      note: note,
      savedAt: old.savedAt,
      updatedAt: DateTime.now(),
      post: old.post,
    );
    _saved[index] = updated;
    return updated;
  }

  @override
  Future<CareerPost> create(CareerPostInput input) =>
      throw UnimplementedError('Visual preview only.');

  @override
  Future<CareerPost> update(int postId, CareerPostInput input) =>
      throw UnimplementedError('Visual preview only.');

  @override
  Future<CareerPost> close(int postId) =>
      throw UnimplementedError('Visual preview only.');
}
