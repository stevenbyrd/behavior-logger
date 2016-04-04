//
//  BLMProjectMenuController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCreateProjectController.h"
#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"


BLMColorHexCode const BLMCreateProjectCellTextColor = BLMColorHexCodeBlue;

static CGFloat const ProjectCellFontSize = 14.0;


typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionProjectList,
    TableSectionCreateProject,
    TableSectionCount
};


#pragma mark

@interface ProjectCell : UITableViewCell

@end


@implementation ProjectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self == nil) {
        return nil;
    }

    self.contentView.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];
    self.textLabel.font = [UIFont systemFontOfSize:ProjectCellFontSize];

    return self;
}

@end


#pragma mark

@interface CreateProjectCell : UITableViewCell

@property (nonatomic, strong, readonly) UIView *separatorView;

@end


@implementation CreateProjectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self == nil) {
        return nil;
    }

    UIColor *contentColor = [BLMViewUtils colorForHexCode:BLMCreateProjectCellTextColor];

    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
                                      NSParagraphStyleAttributeName : [BLMViewUtils centerAlignedParagraphStyle],
                                      NSForegroundColorAttributeName : contentColor };

    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Create New" attributes:textAttributes];
    self.textLabel.numberOfLines = 1;

    _separatorView = [[UIView alloc] initWithFrame:CGRectZero];

    self.separatorView.backgroundColor = contentColor;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.separatorView];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeHeight equalToConstant:1.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeWidth equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeCenterX equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:0.0]];

    self.contentView.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];

    return self;
}

@end


#pragma mark

@interface BLMProjectMenuController () <UITableViewDelegate, UITableViewDataSource, BLMCreateProjectControllerDelegate>

@property (nonatomic, assign, getter=isShowingProjectCreationController) BOOL showingProjectCreationController;
@property (nonatomic, assign, getter=isShowingProjectDetailController) BOOL showingProjectDetailController;
@property (nonatomic, strong) NSUUID *lastShownProjectUUID;
@property (nonatomic, copy, readonly) NSMutableArray<NSUUID *> *projectUUIDs;
@property (nonatomic, strong, readonly) UITableView *tableView;

@end


@implementation BLMProjectMenuController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUUIDs = [NSMutableArray array];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Projects";

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero];

    [self.tableView registerClass:[ProjectCell class] forCellReuseIdentifier:@"ProjectCell"];
    [self.tableView registerClass:[CreateProjectCell class] forCellReuseIdentifier:@"CreateProjectCell"];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.tableView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.tableView equalToItem:self.view]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelArchiveRestored:) name:BLMDataManagerArchiveRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectCreated:) name:BLMProjectCreatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectDeleted:) name:BLMProjectDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectUpdated:) name:BLMProjectUpdatedNotification object:nil];
}

#pragma mark Internal State

- (NSUInteger)insertionIndexForProjectUUID:(NSUUID *)UUID {
    static NSComparator comparator;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        comparator = ^NSComparisonResult(NSUUID *leftUUID, NSUUID *rightUUID) {
            NSString *leftName = [[BLMDataManager sharedManager] projectForUUID:leftUUID].name;
            NSString *rightName = [[BLMDataManager sharedManager] projectForUUID:rightUUID].name;

            assert(leftName != nil);
            assert(rightName != nil);

            return [leftName compare:rightName];
        };
    });

    return [self.projectUUIDs indexOfObject:UUID inSortedRange:NSMakeRange(0, self.projectUUIDs.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
}


- (void)showCreateProjectController {
    assert([NSThread isMainThread]);

    if (self.isShowingProjectCreationController) {
        assert(!self.isShowingProjectDetailController);
        return;
    }

    UINavigationController *splitViewDetailController = self.splitViewController.viewControllers.lastObject;
    splitViewDetailController.viewControllers = @[[[BLMCreateProjectController alloc] initWithDelegate:self]];

    self.showingProjectCreationController = YES;
    self.showingProjectDetailController = NO;
}


- (void)showDetailsForProjectUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert((UUID == nil) || [self.projectUUIDs containsObject:UUID]);

    if ([BLMUtils isObject:UUID equalToObject:self.lastShownProjectUUID] && self.isShowingProjectDetailController) { // Already being shown
        assert(!self.isShowingProjectCreationController);
        return;
    }

    if (UUID != nil) {
        NSUInteger UUIDIndex = [self.projectUUIDs indexOfObject:UUID];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:UUIDIndex inSection:TableSectionProjectList];
        UITableViewScrollPosition scrollPosition = ((self.lastShownProjectUUID == nil) ? UITableViewScrollPositionBottom : UITableViewScrollPositionNone);
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:scrollPosition];
    } else if (self.tableView.indexPathForSelectedRow != nil) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
    }

    UINavigationController *splitViewDetailController = self.splitViewController.viewControllers.lastObject;
    splitViewDetailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProjectUUID:UUID delegate:self]];

    self.showingProjectCreationController = NO;
    self.showingProjectDetailController = YES;
    self.lastShownProjectUUID = UUID;
}

#pragma mark Event Handling

- (void)handleDataModelArchiveRestored:(NSNotification *)notification {
    assert(self.projectUUIDs.count == 0);
    assert(self.lastShownProjectUUID == nil);
    assert(![BLMDataManager sharedManager].isRestoringArchive);

    for (BLMProject *project in [BLMDataManager sharedManager].projectEnumerator) {
        [self.projectUUIDs insertObject:project.UUID atIndex:[self insertionIndexForProjectUUID:project.UUID]];
    }

    [self.tableView reloadData];

    [self showDetailsForProjectUUID:self.projectUUIDs.firstObject];
}


- (void)handleDataModelProjectCreated:(NSNotification *)notification {
    [self.tableView beginUpdates];

    BLMProject *project = (BLMProject *)notification.object;
    NSUInteger UUIDIndex = [self insertionIndexForProjectUUID:project.UUID];

    [self.projectUUIDs insertObject:project.UUID atIndex:UUIDIndex];

    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:UUIDIndex inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    [self.tableView beginUpdates];

    BLMProject *project = (BLMProject *)notification.object;
    NSUInteger UUIDIndex = [self.projectUUIDs indexOfObject:project.UUID];

    [self.projectUUIDs removeObjectAtIndex:UUIDIndex];

    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:UUIDIndex inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];

    if ([BLMUtils isObject:project.UUID equalToObject:self.lastShownProjectUUID]) {
        [self showDetailsForProjectUUID:self.projectUUIDs.firstObject];
    }
}


- (void)handleDataModelProjectUpdated:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSInteger index = [self.projectUUIDs indexOfObject:project.UUID];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return TableSectionCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;

    switch ((TableSection)section) {
        case TableSectionProjectList:
            rowCount = self.projectUUIDs.count;
            break;

        case TableSectionCreateProject:
            rowCount = 1;
            break;

        case TableSectionCount: {
            assert(NO);
            break;
        }
    }

    return rowCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch ((TableSection)indexPath.section) {
        case TableSectionProjectList: {
            ProjectCell *projectCell = [tableView dequeueReusableCellWithIdentifier:@"ProjectCell"];

            NSUUID *UUID = self.projectUUIDs[indexPath.row];
            BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:UUID];
            projectCell.textLabel.text = project.name;

            cell = projectCell;
            break;
        }

        case TableSectionCreateProject: {
            CreateProjectCell *createProjectCell = [tableView dequeueReusableCellWithIdentifier:@"CreateProjectCell"];
            cell = createProjectCell;
            break;
        }

        case TableSectionCount: {
            assert(NO);
            break;
        }
    }

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    assert(!self.splitViewController.isCollapsed);

    switch ((TableSection)indexPath.section) {
        case TableSectionProjectList:
            [self showDetailsForProjectUUID:self.projectUUIDs[indexPath.row]];
            break;

        case TableSectionCreateProject:
            [self showCreateProjectController];
            break;
            
        case TableSectionCount: {
            assert(NO);
            break;
        }
    }
}

#pragma mark BLMCreateProjectControllerDelegate

- (void)createProjectController:(BLMCreateProjectController *)controller didCreateProject:(BLMProject *)project {
    assert([self.projectUUIDs indexOfObject:project.UUID] != NSNotFound);
    [self showDetailsForProjectUUID:project.UUID];
}


- (void)createProjectControllerDidCancel:(BLMCreateProjectController *)controller {
    [self showDetailsForProjectUUID:self.lastShownProjectUUID];
}

@end
